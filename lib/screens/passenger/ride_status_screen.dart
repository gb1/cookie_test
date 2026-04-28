import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ride.dart';
import '../../services/ride_service.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../util/formatters.dart';
import '../../widgets/cork_harbour_map.dart';
import '../common/chat_screen.dart';

class RideStatusScreen extends StatelessWidget {
  const RideStatusScreen({super.key, required this.rideId});

  final String rideId;

  @override
  Widget build(BuildContext context) {
    final user = Session.require(context);
    final rides = context.watch<RideService>();
    final ride = rides.rideById(rideId);

    if (ride == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Trip')),
        body: const Center(child: Text('This ride is no longer available.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your trip'),
        actions: [
          if (ride.driverId != null)
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
          _StatusCard(ride: ride, currentUserId: user.id),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.ride, required this.currentUserId});

  final Ride ride;
  final String currentUserId;

  @override
  Widget build(BuildContext context) {
    final canCancel = !ride.status.isTerminal &&
        ride.status != RideStatus.inProgress;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  ride.status.isTerminal
                      ? Icons.check_circle
                      : Icons.directions_boat,
                  color: AppTheme.harbourTeal,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    ride.status.label,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Text(
                  formatEur(ride.fareEur),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('${ride.pickupLabel}  →  ${ride.dropoffLabel}'),
            const SizedBox(height: 4),
            Text(
              '${formatKm(ride.distanceKm)} • ${formatDuration(Duration(minutes: ride.etaMinutes))}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (ride.driverId != null) ...[
              const Divider(height: 24),
              Row(
                children: [
                  const CircleAvatar(child: Icon(Icons.person)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(ride.driverName ?? 'Driver',
                            style: Theme.of(context).textTheme.titleMedium),
                        if (ride.vesselName != null)
                          Text(ride.vesselName!,
                              style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            ],
            if (canCancel) ...[
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () {
                  context
                      .read<RideService>()
                      .cancelRide(ride.id, currentUserId);
                },
                child: const Text('Cancel trip'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
