import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ride.dart';
import '../../services/ride_service.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../util/formatters.dart';
import '../../widgets/cork_harbour_map.dart';
import '../common/chat_screen.dart';

class DriverTripScreen extends StatelessWidget {
  const DriverTripScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) {
    final user = Session.require(context);
    final rides = context.watch<RideService>();
    final ride = rides.rideById(rideId);

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: const Center(child: Text('Ride not found.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Active trip'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            tooltip: 'Chat',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => ChatScreen(ride: ride),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: CorkHarbourMap(
              center: ride.pickup,
              routeFrom: ride.pickup,
              routeTo: ride.dropoff,
              markers: [
                MapMarkerSpec(
                  point: ride.pickup,
                  icon: Icons.flag,
                  color: AppTheme.harbourNavy,
                  tooltip: 'Pickup',
                ),
                MapMarkerSpec(
                  point: ride.dropoff,
                  icon: Icons.location_on,
                  color: AppTheme.buoyAmber,
                  tooltip: 'Drop-off',
                ),
              ],
            ),
          ),
          _DriverActions(ride: ride, currentUserId: user.id),
        ],
      ),
    );
  }
}

class _DriverActions extends StatelessWidget {
  const _DriverActions({required this.ride, required this.currentUserId});

  final Ride ride;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final next = _nextStatus(ride.status);
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    ride.status.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(formatEur(ride.fareEur),
                    style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: 4),
            Text('${ride.passengerName} • ${ride.pickupLabel} → ${ride.dropoffLabel}'),
            const SizedBox(height: 12),
            if (next != null)
              FilledButton(
                onPressed: () {
                  try {
                    context
                        .read<RideService>()
                        .advanceRide(ride.id, next);
                    if (next == RideStatus.completed && context.mounted) {
                      Navigator.of(context).pop();
                    }
                  } on RideException catch (e) {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(e.message)));
                  }
                },
                child: Text(_nextLabel(next)),
              ),
            if (!ride.status.isTerminal && ride.status != RideStatus.inProgress)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: OutlinedButton(
                  onPressed: () {
                    context
                        .read<RideService>()
                        .cancelRide(ride.id, currentUserId);
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: const Text('Cancel trip'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  RideStatus? _nextStatus(RideStatus s) {
    switch (s) {
      case RideStatus.accepted:
        return RideStatus.driverEnRoute;
      case RideStatus.driverEnRoute:
        return RideStatus.arrivedAtPickup;
      case RideStatus.arrivedAtPickup:
        return RideStatus.inProgress;
      case RideStatus.inProgress:
        return RideStatus.completed;
      case RideStatus.requested:
      case RideStatus.completed:
      case RideStatus.cancelled:
        return null;
    }
  }

  String _nextLabel(RideStatus next) {
    switch (next) {
      case RideStatus.driverEnRoute:
        return 'Cast off (en route)';
      case RideStatus.arrivedAtPickup:
        return 'Arrived at pickup';
      case RideStatus.inProgress:
        return 'Start trip';
      case RideStatus.completed:
        return 'Complete trip';
      default:
        return '';
    }
  }
}
