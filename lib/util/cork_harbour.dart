import 'dart:math' as math;

import 'package:flutter_map/flutter_map.dart' show LatLngBounds;
import 'package:latlong2/latlong.dart';

import '../models/pier.dart';

export 'package:flutter_map/flutter_map.dart' show LatLngBounds;

/// Static facts about Cork Harbour: the bounding box, well-known piers used
/// throughout the app, and the maths we use to estimate trip distance, time
/// and fare.
class CorkHarbour {
  CorkHarbour._();

  /// Default centre of the map - Cobh's Kennedy Pier.
  static const LatLng center = LatLng(51.8506, -8.2944);

  /// Loose bounding box for the harbour. Pickups or drop-offs outside
  /// this rectangle are rejected.
  static final LatLngBounds bounds = LatLngBounds(
    const LatLng(51.78, -8.42),
    const LatLng(51.92, -8.20),
  );

  /// Curated list of piers / quays around the harbour.
  static const List<Pier> piers = <Pier>[
    Pier(
      id: 'cobh',
      name: 'Cobh — Kennedy Pier',
      location: LatLng(51.8506, -8.2944),
    ),
    Pier(
      id: 'crosshaven',
      name: 'Crosshaven',
      location: LatLng(51.8030, -8.3010),
    ),
    Pier(
      id: 'passage_west',
      name: 'Passage West',
      location: LatLng(51.8728, -8.3422),
    ),
    Pier(
      id: 'monkstown',
      name: 'Monkstown',
      location: LatLng(51.8728, -8.3611),
    ),
    Pier(
      id: 'aghada',
      name: 'Aghada',
      location: LatLng(51.8367, -8.2225),
    ),
    Pier(
      id: 'ringaskiddy',
      name: 'Ringaskiddy',
      location: LatLng(51.8344, -8.3175),
    ),
    Pier(
      id: 'spike_island',
      name: 'Spike Island',
      location: LatLng(51.8392, -8.2861),
    ),
    Pier(
      id: 'haulbowline',
      name: 'Haulbowline',
      location: LatLng(51.8389, -8.2997),
    ),
    Pier(
      id: 'cork_city_quay',
      name: 'Cork City — Custom House Quay',
      location: LatLng(51.8985, -8.4706),
    ),
  ];

  static Pier pierById(String id) =>
      piers.firstWhere((p) => p.id == id, orElse: () => piers.first);

  /// Great-circle distance in kilometres between two points.
  static double distanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _deg2rad(b.latitude - a.latitude);
    final dLon = _deg2rad(b.longitude - a.longitude);
    final lat1 = _deg2rad(a.latitude);
    final lat2 = _deg2rad(b.latitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusKm * c;
  }

  /// Cruise speed assumption used for ETA: ~15 knots.
  static const double cruiseKmPerHour = 27.78;

  static Duration estimatedDuration(LatLng a, LatLng b) {
    final hours = distanceKm(a, b) / cruiseKmPerHour;
    return Duration(seconds: (hours * 3600).round());
  }

  /// Fare in EUR. Base + per-km + per-minute, rounded to nearest €0.50,
  /// with a €7 minimum so a hop across the harbour isn't free.
  static double estimateFare(LatLng a, LatLng b) {
    final km = distanceKm(a, b);
    final minutes = (km / cruiseKmPerHour) * 60.0;
    final raw = 5.00 + 2.00 * km + 0.50 * minutes;
    final rounded = (raw * 2).round() / 2.0;
    return math.max(rounded, 7.0);
  }

  static bool contains(LatLng point) => bounds.contains(point);

  /// The pier closest to [point], used as a sensible default pickup.
  static Pier nearestPier(LatLng point) {
    Pier best = piers.first;
    double bestDist = double.infinity;
    for (final p in piers) {
      final d = distanceKm(point, p.location);
      if (d < bestDist) {
        bestDist = d;
        best = p;
      }
    }
    return best;
  }

  static double _deg2rad(double deg) => deg * (math.pi / 180.0);
}
