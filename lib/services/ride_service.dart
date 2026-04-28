import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/ride.dart';
import '../util/cork_harbour.dart';

/// In-memory matchmaker for rides. Both passenger and driver UIs read from
/// the same instance (provided at the top of the widget tree), so creating a
/// ride in one tab/screen makes it visible to the other.
class RideService extends ChangeNotifier {
  RideService(this._prefs) {
    _restoreHistory();
  }

  static const _kHistory = 'rides.history';

  final SharedPreferences _prefs;
  final _uuid = const Uuid();

  final Map<String, AppUser> _onlineDrivers = <String, AppUser>{};
  final List<Ride> _pending = <Ride>[];
  final List<Ride> _active = <Ride>[];
  final List<Ride> _history = <Ride>[];

  List<AppUser> get onlineDrivers => List.unmodifiable(_onlineDrivers.values);
  List<Ride> get pendingRequests => List.unmodifiable(_pending);
  List<Ride> get activeRides => List.unmodifiable(_active);
  List<Ride> get history => List.unmodifiable(_history);

  // ─── driver presence ────────────────────────────────────────────────

  void setDriverOnline(AppUser driver, {bool online = true}) {
    if (online) {
      _onlineDrivers[driver.id] = driver;
    } else {
      _onlineDrivers.remove(driver.id);
    }
    notifyListeners();
  }

  bool isDriverOnline(String driverId) =>
      _onlineDrivers.containsKey(driverId);

  // ─── lookups ────────────────────────────────────────────────────────

  Ride? activeFor(String userId) {
    for (final r in _active) {
      if (r.involves(userId)) return r;
    }
    return null;
  }

  Ride? pendingFor(String passengerId) {
    for (final r in _pending) {
      if (r.passengerId == passengerId) return r;
    }
    return null;
  }

  Ride? rideById(String id) {
    for (final r in _pending) {
      if (r.id == id) return r;
    }
    for (final r in _active) {
      if (r.id == id) return r;
    }
    for (final r in _history) {
      if (r.id == id) return r;
    }
    return null;
  }

  List<Ride> historyFor(String userId) =>
      _history.where((r) => r.involves(userId)).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  /// Pending rides a driver could accept. Limited to those with a pickup
  /// inside the harbour bounds (already enforced on creation, but kept here
  /// as a safety net).
  List<Ride> pendingForDriver(AppUser driver) {
    return _pending.where((r) => CorkHarbour.contains(r.pickup)).toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  // ─── lifecycle ──────────────────────────────────────────────────────

  Ride requestRide({
    required AppUser passenger,
    required LatLng pickup,
    required String pickupLabel,
    required LatLng dropoff,
    required String dropoffLabel,
  }) {
    if (!CorkHarbour.contains(pickup) || !CorkHarbour.contains(dropoff)) {
      throw const RideException('Both points must be inside Cork Harbour.');
    }
    if (pendingFor(passenger.id) != null || activeFor(passenger.id) != null) {
      throw const RideException('You already have an active trip.');
    }

    final km = CorkHarbour.distanceKm(pickup, dropoff);
    final eta = CorkHarbour.estimatedDuration(pickup, dropoff);
    final fare = CorkHarbour.estimateFare(pickup, dropoff);

    final ride = Ride(
      id: _uuid.v4(),
      passengerId: passenger.id,
      passengerName: passenger.name,
      pickup: pickup,
      pickupLabel: pickupLabel,
      dropoff: dropoff,
      dropoffLabel: dropoffLabel,
      distanceKm: km,
      etaMinutes: eta.inMinutes,
      fareEur: fare,
    );
    _pending.add(ride);
    notifyListeners();
    return ride;
  }

  Ride acceptRide(String rideId, AppUser driver) {
    final idx = _pending.indexWhere((r) => r.id == rideId);
    if (idx == -1) {
      throw const RideException('That ride is no longer available.');
    }
    if (activeFor(driver.id) != null) {
      throw const RideException('You already have an active trip.');
    }
    final ride = _pending.removeAt(idx);
    ride.driverId = driver.id;
    ride.driverName = driver.name;
    ride.vesselName = driver.vesselName;
    ride.status = RideStatus.accepted;
    _active.add(ride);
    notifyListeners();
    return ride;
  }

  void advanceRide(String rideId, RideStatus next) {
    final ride = _findActive(rideId);
    if (!_isValidTransition(ride.status, next)) {
      throw RideException('Cannot move ride from ${ride.status.name} '
          'to ${next.name}.');
    }
    ride.status = next;
    if (next == RideStatus.completed) {
      ride.completedAt = DateTime.now();
      _active.remove(ride);
      _history.insert(0, ride);
      _persistHistory();
    }
    notifyListeners();
  }

  void cancelRide(String rideId, String byUserId) {
    // Try pending first.
    final pIdx = _pending.indexWhere((r) => r.id == rideId);
    if (pIdx != -1) {
      final ride = _pending.removeAt(pIdx);
      ride.status = RideStatus.cancelled;
      ride.cancelledByUserId = byUserId;
      ride.completedAt = DateTime.now();
      _history.insert(0, ride);
      _persistHistory();
      notifyListeners();
      return;
    }
    final aIdx = _active.indexWhere((r) => r.id == rideId);
    if (aIdx != -1) {
      final ride = _active.removeAt(aIdx);
      ride.status = RideStatus.cancelled;
      ride.cancelledByUserId = byUserId;
      ride.completedAt = DateTime.now();
      _history.insert(0, ride);
      _persistHistory();
      notifyListeners();
    }
  }

  // ─── internals ──────────────────────────────────────────────────────

  Ride _findActive(String rideId) {
    for (final r in _active) {
      if (r.id == rideId) return r;
    }
    throw const RideException('Ride is not active.');
  }

  bool _isValidTransition(RideStatus from, RideStatus to) {
    const map = <RideStatus, Set<RideStatus>>{
      RideStatus.accepted: {RideStatus.driverEnRoute, RideStatus.cancelled},
      RideStatus.driverEnRoute: {
        RideStatus.arrivedAtPickup,
        RideStatus.cancelled,
      },
      RideStatus.arrivedAtPickup: {
        RideStatus.inProgress,
        RideStatus.cancelled,
      },
      RideStatus.inProgress: {RideStatus.completed},
    };
    return map[from]?.contains(to) ?? false;
  }

  void _restoreHistory() {
    final raw = _prefs.getString(_kHistory);
    if (raw == null || raw.isEmpty) return;
    try {
      _history.addAll(Ride.decodeList(raw));
    } catch (_) {
      // Ignore corrupt history; start fresh.
    }
  }

  Future<void> _persistHistory() async {
    // Cap stored history at 100 rides to keep prefs small.
    final capped = _history.take(100).toList();
    await _prefs.setString(_kHistory, Ride.encodeList(capped));
  }
}

class RideException implements Exception {
  const RideException(this.message);
  final String message;
  @override
  String toString() => message;
}
