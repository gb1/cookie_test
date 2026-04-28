import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';
import '../models/ride.dart';
import '../util/cork_harbour.dart';
import 'auth_service.dart';

/// Postgres-backed ride matchmaker. Holds a local cache of rides hydrated
/// from `public.rides` plus a realtime subscription so passenger and driver
/// UIs (in different browsers / on different devices) update each other.
class RideService extends ChangeNotifier {
  RideService({required SupabaseClient client, required AuthService auth})
      : _client = client,
        _auth = auth {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  final SupabaseClient _client;
  final AuthService _auth;

  // Cache, keyed by ride id, hydrated from realtime + initial fetch.
  final Map<String, Ride> _rides = <String, Ride>{};

  RealtimeChannel? _ridesChannel;
  RealtimeChannel? _profilesChannel;

  // Online drivers, keyed by id, sourced from profiles.is_online_driver.
  final Map<String, AppUser> _onlineDrivers = <String, AppUser>{};

  String? _currentUserId;

  // ─── public API (matches the previous in-memory service) ────────────

  List<AppUser> get onlineDrivers => List.unmodifiable(_onlineDrivers.values);

  List<Ride> get pendingRequests => _rides.values
      .where((r) => r.status == RideStatus.requested)
      .toList()
    ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  List<Ride> get activeRides => _rides.values
      .where((r) =>
          r.status != RideStatus.requested && !r.status.isTerminal)
      .toList();

  List<Ride> get history => _rides.values
      .where((r) => r.status.isTerminal)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  bool isDriverOnline(String driverId) =>
      _onlineDrivers.containsKey(driverId);

  Ride? rideById(String id) => _rides[id];

  Ride? activeFor(String userId) {
    for (final r in _rides.values) {
      if (r.involves(userId) &&
          r.status != RideStatus.requested &&
          !r.status.isTerminal) {
        return r;
      }
    }
    return null;
  }

  Ride? pendingFor(String passengerId) {
    for (final r in _rides.values) {
      if (r.passengerId == passengerId &&
          r.status == RideStatus.requested) {
        return r;
      }
    }
    return null;
  }

  List<Ride> historyFor(String userId) =>
      _rides.values
          .where((r) => r.involves(userId) && r.status.isTerminal)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  List<Ride> pendingForDriver(AppUser driver) =>
      _rides.values
          .where((r) =>
              r.status == RideStatus.requested &&
              CorkHarbour.contains(r.pickup))
          .toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  // ─── lifecycle commands ─────────────────────────────────────────────

  Future<void> setDriverOnline(AppUser driver, {bool online = true}) async {
    await _client
        .from('profiles')
        .update({'is_online_driver': online}).eq('id', driver.id);
    if (online) {
      _onlineDrivers[driver.id] = driver;
    } else {
      _onlineDrivers.remove(driver.id);
    }
    notifyListeners();
  }

  Future<Ride> requestRide({
    required AppUser passenger,
    required LatLng pickup,
    required String pickupLabel,
    required LatLng dropoff,
    required String dropoffLabel,
  }) async {
    if (!CorkHarbour.contains(pickup) || !CorkHarbour.contains(dropoff)) {
      throw const RideException('Both points must be inside Cork Harbour.');
    }
    if (pendingFor(passenger.id) != null || activeFor(passenger.id) != null) {
      throw const RideException('You already have an active trip.');
    }

    final km = CorkHarbour.distanceKm(pickup, dropoff);
    final eta = CorkHarbour.estimatedDuration(pickup, dropoff);
    final fare = CorkHarbour.estimateFare(pickup, dropoff);

    final inserted = await _client
        .from('rides')
        .insert({
          'passenger_id': passenger.id,
          'passenger_name': passenger.name,
          'pickup_lat': pickup.latitude,
          'pickup_lng': pickup.longitude,
          'pickup_label': pickupLabel,
          'dropoff_lat': dropoff.latitude,
          'dropoff_lng': dropoff.longitude,
          'dropoff_label': dropoffLabel,
          'distance_km': km,
          'eta_minutes': eta.inMinutes,
          'fare_eur': fare,
          'status': 'requested',
        })
        .select()
        .single();

    final ride = _rideFromRow(inserted);
    _rides[ride.id] = ride;
    notifyListeners();
    return ride;
  }

  Future<Ride> acceptRide(String rideId, AppUser driver) async {
    if (activeFor(driver.id) != null) {
      throw const RideException('You already have an active trip.');
    }
    final updated = await _client
        .from('rides')
        .update({
          'driver_id': driver.id,
          'driver_name': driver.name,
          'vessel_name': driver.vesselName,
          'status': 'accepted',
        })
        .eq('id', rideId)
        .eq('status', 'requested')
        .select()
        .maybeSingle();
    if (updated == null) {
      throw const RideException('That ride is no longer available.');
    }
    final ride = _rideFromRow(updated);
    _rides[ride.id] = ride;
    notifyListeners();
    return ride;
  }

  Future<void> advanceRide(String rideId, RideStatus next) async {
    final current = _rides[rideId];
    if (current == null) {
      throw const RideException('Ride not found.');
    }
    if (!isValidRideTransition(current.status, next)) {
      throw RideException('Cannot move ride from ${current.status.name} '
          'to ${next.name}.');
    }
    final patch = <String, dynamic>{'status': next.name};
    if (next == RideStatus.completed) {
      patch['completed_at'] = DateTime.now().toUtc().toIso8601String();
    }
    final updated = await _client
        .from('rides')
        .update(patch)
        .eq('id', rideId)
        .select()
        .single();
    _rides[rideId] = _rideFromRow(updated);
    notifyListeners();
  }

  Future<void> cancelRide(String rideId, String byUserId) async {
    final updated = await _client
        .from('rides')
        .update({
          'status': 'cancelled',
          'cancelled_by_user_id': byUserId,
          'completed_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', rideId)
        .select()
        .single();
    _rides[rideId] = _rideFromRow(updated);
    notifyListeners();
  }

  // ─── realtime + hydration ───────────────────────────────────────────

  void _onAuthChanged() {
    final user = _auth.currentUser;
    if (user == null) {
      _disconnect();
      return;
    }
    if (user.id == _currentUserId) return;
    _currentUserId = user.id;
    _connect();
  }

  Future<void> _connect() async {
    _disconnect();
    await _hydrateRides();
    await _hydrateOnlineDrivers();

    _ridesChannel = _client
        .channel('public:rides')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'rides',
          callback: (payload) {
            switch (payload.eventType) {
              case PostgresChangeEvent.insert:
              case PostgresChangeEvent.update:
                final row = payload.newRecord;
                if (row.isNotEmpty) {
                  _rides[row['id'] as String] = _rideFromRow(row);
                  notifyListeners();
                }
                break;
              case PostgresChangeEvent.delete:
                final old = payload.oldRecord;
                if (old.isNotEmpty) {
                  _rides.remove(old['id']);
                  notifyListeners();
                }
                break;
              case PostgresChangeEvent.all:
                break;
            }
          },
        )
        .subscribe();

    _profilesChannel = _client
        .channel('public:profiles')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            final row = payload.newRecord;
            if (row.isEmpty) return;
            final id = row['id'] as String;
            final isOnline = row['is_online_driver'] as bool? ?? false;
            final isDriver = row['role'] == 'driver';
            if (isDriver && isOnline) {
              _onlineDrivers[id] = AppUser(
                id: id,
                email: row['email'] as String? ?? '',
                name: row['name'] as String? ?? '',
                role: UserRole.driver,
                vesselName: row['vessel_name'] as String?,
                vesselCapacity: row['vessel_capacity'] as int?,
              );
            } else {
              _onlineDrivers.remove(id);
            }
            notifyListeners();
          },
        )
        .subscribe();
  }

  void _disconnect() {
    if (_ridesChannel != null) {
      _client.removeChannel(_ridesChannel!);
      _ridesChannel = null;
    }
    if (_profilesChannel != null) {
      _client.removeChannel(_profilesChannel!);
      _profilesChannel = null;
    }
    _rides.clear();
    _onlineDrivers.clear();
    _currentUserId = null;
    notifyListeners();
  }

  Future<void> _hydrateRides() async {
    final rows = await _client
        .from('rides')
        .select()
        .order('created_at', ascending: false)
        .limit(200);
    _rides.clear();
    for (final row in rows) {
      final r = _rideFromRow(row);
      _rides[r.id] = r;
    }
    notifyListeners();
  }

  Future<void> _hydrateOnlineDrivers() async {
    final rows = await _client
        .from('profiles')
        .select()
        .eq('role', 'driver')
        .eq('is_online_driver', true);
    _onlineDrivers.clear();
    for (final row in rows) {
      _onlineDrivers[row['id'] as String] = AppUser(
        id: row['id'] as String,
        email: row['email'] as String? ?? '',
        name: row['name'] as String? ?? '',
        role: UserRole.driver,
        vesselName: row['vessel_name'] as String?,
        vesselCapacity: row['vessel_capacity'] as int?,
      );
    }
    notifyListeners();
  }

  // ─── helpers ────────────────────────────────────────────────────────

  Ride _rideFromRow(Map<String, dynamic> row) {
    return Ride(
      id: row['id'] as String,
      passengerId: row['passenger_id'] as String,
      passengerName: row['passenger_name'] as String? ?? 'Passenger',
      driverId: row['driver_id'] as String?,
      driverName: row['driver_name'] as String?,
      vesselName: row['vessel_name'] as String?,
      pickup: LatLng(
        (row['pickup_lat'] as num).toDouble(),
        (row['pickup_lng'] as num).toDouble(),
      ),
      pickupLabel: row['pickup_label'] as String,
      dropoff: LatLng(
        (row['dropoff_lat'] as num).toDouble(),
        (row['dropoff_lng'] as num).toDouble(),
      ),
      dropoffLabel: row['dropoff_label'] as String,
      distanceKm: (row['distance_km'] as num).toDouble(),
      etaMinutes: (row['eta_minutes'] as num).toInt(),
      fareEur: (row['fare_eur'] as num).toDouble(),
      status: RideStatus.values.firstWhere(
        (s) => s.name == row['status'],
        orElse: () => RideStatus.requested,
      ),
      createdAt: DateTime.parse(row['created_at'] as String),
      completedAt: row['completed_at'] == null
          ? null
          : DateTime.parse(row['completed_at'] as String),
      cancelledByUserId: row['cancelled_by_user_id'] as String?,
    );
  }

  @override
  void dispose() {
    _auth.removeListener(_onAuthChanged);
    _disconnect();
    super.dispose();
  }
}

class RideException implements Exception {
  const RideException(this.message);
  final String message;
  @override
  String toString() => message;
}
