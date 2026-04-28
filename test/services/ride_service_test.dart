import 'package:boats/models/ride.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isValidRideTransition', () {
    test('accepted can move forward or be cancelled', () {
      expect(
        isValidRideTransition(RideStatus.accepted, RideStatus.driverEnRoute),
        isTrue,
      );
      expect(
        isValidRideTransition(RideStatus.accepted, RideStatus.cancelled),
        isTrue,
      );
    });

    test('cannot skip statuses', () {
      expect(
        isValidRideTransition(RideStatus.accepted, RideStatus.completed),
        isFalse,
      );
      expect(
        isValidRideTransition(RideStatus.requested, RideStatus.inProgress),
        isFalse,
      );
    });

    test('inProgress only goes to completed', () {
      expect(
        isValidRideTransition(RideStatus.inProgress, RideStatus.completed),
        isTrue,
      );
      expect(
        isValidRideTransition(RideStatus.inProgress, RideStatus.cancelled),
        isFalse,
      );
    });

    test('terminal states are dead ends', () {
      expect(
        isValidRideTransition(RideStatus.completed, RideStatus.inProgress),
        isFalse,
      );
      expect(
        isValidRideTransition(RideStatus.cancelled, RideStatus.requested),
        isFalse,
      );
    });

    test('isTerminal flag', () {
      expect(RideStatus.completed.isTerminal, isTrue);
      expect(RideStatus.cancelled.isTerminal, isTrue);
      expect(RideStatus.requested.isTerminal, isFalse);
      expect(RideStatus.inProgress.isTerminal, isFalse);
    });
  });
}
