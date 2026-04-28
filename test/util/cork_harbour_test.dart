import 'package:boats/util/cork_harbour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';

void main() {
  group('CorkHarbour', () {
    test('contains points inside the harbour', () {
      expect(CorkHarbour.contains(const LatLng(51.85, -8.30)), isTrue);
    });

    test('rejects points well outside the harbour', () {
      // Dublin
      expect(CorkHarbour.contains(const LatLng(53.35, -6.26)), isFalse);
    });

    test('distance between Cobh and Crosshaven is sensible', () {
      final cobh = CorkHarbour.pierById('cobh').location;
      final cross = CorkHarbour.pierById('crosshaven').location;
      final km = CorkHarbour.distanceKm(cobh, cross);
      expect(km, greaterThan(4));
      expect(km, lessThan(10));
    });

    test('fare meets the €7 minimum even for very short hops', () {
      const a = LatLng(51.85, -8.30);
      const b = LatLng(51.851, -8.301);
      expect(CorkHarbour.estimateFare(a, b), greaterThanOrEqualTo(7.0));
    });

    test('fare grows with distance', () {
      const a = LatLng(51.85, -8.30);
      const b = LatLng(51.86, -8.32);
      const c = LatLng(51.90, -8.40);
      expect(
        CorkHarbour.estimateFare(a, c),
        greaterThan(CorkHarbour.estimateFare(a, b)),
      );
    });

    test('nearestPier picks the closest known pier', () {
      // A point right by Cobh.
      const nearCobh = LatLng(51.851, -8.295);
      expect(CorkHarbour.nearestPier(nearCobh).id, 'cobh');
    });
  });
}
