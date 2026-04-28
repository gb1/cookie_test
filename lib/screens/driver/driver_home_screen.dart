import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/ride.dart';
import '../../services/ride_service.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../widgets/cork_harbour_map.dart';
import '../../widgets/ride_request_card.dart';
import 'driver_trip_screen.dart';

class DriverHomeScreen extends StatelessWidget {
  const DriverHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Session.require(context);
    final rides = context.watch<RideService>();
    final online = rides.isDriverOnline(user.id);
    final active = rides.activeFor(user.id);
    final pending = rides.pendingForDriver(user);

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: CorkHarbourMap(
            markers: pending
                .map(
                  (r) => MapMarkerSpec(
                    point: r.pickup,
                    icon: Icons.flag,
                    color: AppTheme.buoyAmber,
                    tooltip: '${r.passengerName} • ${r.pickupLabel}',
                  ),
                )
                .toList(),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    online ? Icons.cloud_done : Icons.cloud_off,
                    color: online ? AppTheme.harbourTeal : Colors.grey,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(online ? 'Online' : 'Offline',
                            style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          user.vesselName ?? 'Set up your vessel in Profile',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: online,
                    onChanged: (v) => context
                        .read<RideService>()
                        .setDriverOnline(user, online: v),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (active != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              color: AppTheme.harbourTeal.withOpacity(0.1),
              child: ListTile(
                leading: const Icon(Icons.directions_boat,
                    color: AppTheme.harbourTeal),
                title: const Text('Active trip'),
                subtitle: Text(
                    '${active.passengerName} • ${active.pickupLabel} → ${active.dropoffLabel}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => DriverTripScreen(rideId: active.id),
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: !online
              ? const _OfflineHint()
              : pending.isEmpty
                  ? const _NoRequests()
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: pending.length,
                      itemBuilder: (context, i) {
                        final ride = pending[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: RideRequestCard(
                            ride: ride,
                            onAccept: () => _accept(context, ride),
                            onDecline: () {},
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Future<void> _accept(BuildContext context, Ride ride) async {
    final user = Session.require(context);
    try {
      final accepted =
          await context.read<RideService>().acceptRide(ride.id, user);
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DriverTripScreen(rideId: accepted.id),
        ),
      );
    } on RideException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    }
  }
}

class _OfflineHint extends StatelessWidget {
  const _OfflineHint();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Go online to start receiving ride requests.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _NoRequests extends StatelessWidget {
  const _NoRequests();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.waves, size: 48, color: AppTheme.harbourTeal),
            SizedBox(height: 12),
            Text('Calm waters - no requests right now.'),
          ],
        ),
      ),
    );
  }
}
