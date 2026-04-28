import 'dart:convert';

import 'package:latlong2/latlong.dart';

enum RideStatus {
  requested,
  accepted,
  driverEnRoute,
  arrivedAtPickup,
  inProgress,
  completed,
  cancelled,
}

extension RideStatusX on RideStatus {
  String get label {
    switch (this) {
      case RideStatus.requested:
        return 'Looking for a boat';
      case RideStatus.accepted:
        return 'Boat accepted';
      case RideStatus.driverEnRoute:
        return 'Driver on the way';
      case RideStatus.arrivedAtPickup:
        return 'Driver has arrived';
      case RideStatus.inProgress:
        return 'On the water';
      case RideStatus.completed:
        return 'Trip complete';
      case RideStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isTerminal =>
      this == RideStatus.completed || this == RideStatus.cancelled;
}

class Ride {
  Ride({
    required this.id,
    required this.passengerId,
    required this.passengerName,
    this.driverId,
    this.driverName,
    this.vesselName,
    required this.pickup,
    required this.pickupLabel,
    required this.dropoff,
    required this.dropoffLabel,
    required this.distanceKm,
    required this.etaMinutes,
    required this.fareEur,
    this.status = RideStatus.requested,
    DateTime? createdAt,
    this.completedAt,
    this.cancelledByUserId,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  final String passengerId;
  final String passengerName;

  String? driverId;
  String? driverName;
  String? vesselName;

  final LatLng pickup;
  final String pickupLabel;
  final LatLng dropoff;
  final String dropoffLabel;

  final double distanceKm;
  final int etaMinutes;
  final double fareEur;

  RideStatus status;
  final DateTime createdAt;
  DateTime? completedAt;
  String? cancelledByUserId;

  bool involves(String userId) =>
      passengerId == userId || driverId == userId;

  String partnerNameFor(String userId) =>
      userId == passengerId ? (driverName ?? 'Driver') : passengerName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'passengerId': passengerId,
        'passengerName': passengerName,
        'driverId': driverId,
        'driverName': driverName,
        'vesselName': vesselName,
        'pickup': [pickup.latitude, pickup.longitude],
        'pickupLabel': pickupLabel,
        'dropoff': [dropoff.latitude, dropoff.longitude],
        'dropoffLabel': dropoffLabel,
        'distanceKm': distanceKm,
        'etaMinutes': etaMinutes,
        'fareEur': fareEur,
        'status': status.name,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'cancelledByUserId': cancelledByUserId,
      };

  factory Ride.fromJson(Map<String, dynamic> j) {
    final p = (j['pickup'] as List).cast<num>();
    final d = (j['dropoff'] as List).cast<num>();
    return Ride(
      id: j['id'] as String,
      passengerId: j['passengerId'] as String,
      passengerName: j['passengerName'] as String,
      driverId: j['driverId'] as String?,
      driverName: j['driverName'] as String?,
      vesselName: j['vesselName'] as String?,
      pickup: LatLng(p[0].toDouble(), p[1].toDouble()),
      pickupLabel: j['pickupLabel'] as String,
      dropoff: LatLng(d[0].toDouble(), d[1].toDouble()),
      dropoffLabel: j['dropoffLabel'] as String,
      distanceKm: (j['distanceKm'] as num).toDouble(),
      etaMinutes: (j['etaMinutes'] as num).toInt(),
      fareEur: (j['fareEur'] as num).toDouble(),
      status: RideStatus.values.firstWhere((s) => s.name == j['status']),
      createdAt: DateTime.parse(j['createdAt'] as String),
      completedAt: j['completedAt'] == null
          ? null
          : DateTime.parse(j['completedAt'] as String),
      cancelledByUserId: j['cancelledByUserId'] as String?,
    );
  }

  static String encodeList(List<Ride> rides) =>
      jsonEncode(rides.map((r) => r.toJson()).toList());

  static List<Ride> decodeList(String s) =>
      (jsonDecode(s) as List)
          .map((m) => Ride.fromJson(m as Map<String, dynamic>))
          .toList();
}
