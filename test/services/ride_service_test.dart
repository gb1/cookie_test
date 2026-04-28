import 'package:boats/models/app_user.dart';
import 'package:boats/models/ride.dart';
import 'package:boats/services/ride_service.dart';
import 'package:boats/util/cork_harbour.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';

AppUser _passenger() => const AppUser(
      id: 'p1',
      email: 'p@x',
      name: 'Pat',
      role: UserRole.passenger,
    );

AppUser _driver() => const AppUser(
      id: 'd1',
      email: 'd@x',
      name: 'Dee',
      role: UserRole.driver,
      vesselName: 'Lee Ferry',
      vesselCapacity: 8,
    );

LatLng get _cobh => CorkHarbour.pierById('cobh').location;
LatLng get _crosshaven => CorkHarbour.pierById('crosshaven').location;

void main() {
  late RideService service;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    service = RideService(prefs);
  });

  test('happy path: request -> accept -> en route -> arrive -> trip -> complete',
      () {
    final ride = service.requestRide(
      passenger: _passenger(),
      pickup: _cobh,
      pickupLabel: 'Cobh',
      dropoff: _crosshaven,
      dropoffLabel: 'Crosshaven',
    );
    expect(ride.status, RideStatus.requested);
    expect(service.pendingRequests, hasLength(1));

    final accepted = service.acceptRide(ride.id, _driver());
    expect(accepted.status, RideStatus.accepted);
    expect(service.pendingRequests, isEmpty);
    expect(service.activeRides, hasLength(1));
    expect(accepted.driverId, 'd1');

    service.advanceRide(ride.id, RideStatus.driverEnRoute);
    service.advanceRide(ride.id, RideStatus.arrivedAtPickup);
    service.advanceRide(ride.id, RideStatus.inProgress);
    service.advanceRide(ride.id, RideStatus.completed);

    expect(service.activeRides, isEmpty);
    expect(service.history, hasLength(1));
    expect(service.history.first.status, RideStatus.completed);
    expect(service.history.first.completedAt, isNotNull);
  });

  test('passenger may not have two pending rides', () {
    service.requestRide(
      passenger: _passenger(),
      pickup: _cobh,
      pickupLabel: 'Cobh',
      dropoff: _crosshaven,
      dropoffLabel: 'Crosshaven',
    );
    expect(
      () => service.requestRide(
        passenger: _passenger(),
        pickup: _cobh,
        pickupLabel: 'Cobh',
        dropoff: _crosshaven,
        dropoffLabel: 'Crosshaven',
      ),
      throwsA(isA<RideException>()),
    );
  });

  test('cannot skip status transitions', () {
    final ride = service.requestRide(
      passenger: _passenger(),
      pickup: _cobh,
      pickupLabel: 'Cobh',
      dropoff: _crosshaven,
      dropoffLabel: 'Crosshaven',
    );
    service.acceptRide(ride.id, _driver());

    expect(
      () => service.advanceRide(ride.id, RideStatus.completed),
      throwsA(isA<RideException>()),
    );
  });

  test('rejects out-of-bounds pickups', () {
    expect(
      () => service.requestRide(
        passenger: _passenger(),
        pickup: const LatLng(53.35, -6.26), // Dublin
        pickupLabel: 'Dublin',
        dropoff: _crosshaven,
        dropoffLabel: 'Crosshaven',
      ),
      throwsA(isA<RideException>()),
    );
  });

  test('cancel from pending moves ride to history as cancelled', () {
    final ride = service.requestRide(
      passenger: _passenger(),
      pickup: _cobh,
      pickupLabel: 'Cobh',
      dropoff: _crosshaven,
      dropoffLabel: 'Crosshaven',
    );
    service.cancelRide(ride.id, 'p1');
    expect(service.pendingRequests, isEmpty);
    expect(service.history, hasLength(1));
    expect(service.history.first.status, RideStatus.cancelled);
    expect(service.history.first.cancelledByUserId, 'p1');
  });

  test('driver online toggling', () {
    final d = _driver();
    expect(service.isDriverOnline(d.id), isFalse);
    service.setDriverOnline(d);
    expect(service.isDriverOnline(d.id), isTrue);
    service.setDriverOnline(d, online: false);
    expect(service.isDriverOnline(d.id), isFalse);
  });
}
