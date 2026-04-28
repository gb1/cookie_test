import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ride.dart';
import '../../services/location_service.dart';
import '../../services/ride_service.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../util/cork_harbour.dart';
import '../../widgets/cork_harbour_map.dart';
import 'request_ride_screen.dart';
import 'ride_status_screen.dart';

class PassengerHomeScreen extends StatelessWidget {
  const PassengerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Session.require(context);
    final rides = context.watch<RideService>();
    final location = context.watch<LocationService>();

    final activeRide = rides.activeFor(user.id) ?? rides.pendingFor(user.id);

    final driverMarkers = rides.onlineDrivers
        .map(
          (d) => MapMarkerSpec(
            point: CorkHarbour.center,
            icon: Icons.directions_boat,
            color: AppTheme.harbourTeal,
            tooltip: '${d.name} • ${d.vesselName ?? ''}',
          ),
        )
        .toList();

    return Stack(
      children: [
        Positioned.fill(
          child: CorkHarbourMap(
            center: location.current,
            markers: [
              MapMarkerSpec(
                point: location.current,
                icon: Icons.my_location,
                color: AppTheme.harbourNavy,
                tooltip: 'You',
              ),
              ...driverMarkers,
            ],
          ),
        ),
        Positioned(
          left: 16,
          right: 16,
          bottom: 24,
          child: SafeArea(
            child: activeRide != null
                ? _ActiveRideBanner(rideId: activeRide.id)
                : const _WhereToCard(),
          ),
        ),
      ],
    );
  }
}

class _WhereToCard extends StatelessWidget {
  const _WhereToCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Going somewhere on the water?',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton.icon(
              icon: const Icon(Icons.search),
              label: const Text('Where to?'),
              onPressed: () async {
                final user = Session.require(context);
                final location = context.read<LocationService>();
                final defaultPickup = CorkHarbour.nearestPier(location.current);
                await Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => RequestRideScreen(
                      passenger: user,
                      defaultPickup: defaultPickup,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Pickup defaults to the nearest pier; you can change it on the next screen.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveRideBanner extends StatelessWidget {
  const _ActiveRideBanner({required this.rideId});
  final String rideId;

  @override
  Widget build(BuildContext context) {
    final ride = context.read<RideService>().rideById(rideId);
    if (ride == null) return const SizedBox.shrink();
    return Card(
      child: ListTile(
        leading: const Icon(Icons.directions_boat,
            color: AppTheme.harbourTeal, size: 32),
        title: Text(ride.status.label),
        subtitle: Text('${ride.pickupLabel}  →  ${ride.dropoffLabel}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => RideStatusScreen(rideId: ride.id),
          ),
        ),
      ),
    );
  }
}
