import 'package:boats/models/ride.dart';
import 'package:flutter_test/flutter_test.dart';

// The full app needs a live Supabase client to boot, so widget-level
// smoke tests are deferred to `flutter run`. This file just keeps a
// trivial sanity check so `flutter test` exercises the package's main
// imports.
void main() {
  test('RideStatus enum is well-formed', () {
    expect(RideStatus.values, hasLength(7));
    expect(RideStatus.values.first, RideStatus.requested);
  });
}
