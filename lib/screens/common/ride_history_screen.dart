import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../models/ride.dart';
import '../../services/ride_service.dart';
import '../../state/session.dart';
import '../../theme.dart';
import '../../util/formatters.dart';

class RideHistoryScreen extends StatelessWidget {
  const RideHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Session.require(context);
    final rides = context.watch<RideService>().historyFor(user.id);

    if (rides.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No trips yet. Your history will appear here.'),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      itemCount: rides.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _HistoryTile(ride: rides[i], user: user),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.ride, required this.user});

  final Ride ride;
  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final isCancelled = ride.status == RideStatus.cancelled;
    final partner = ride.partnerNameFor(user.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isCancelled
                  ? Colors.grey.shade300
                  : AppTheme.harbourTeal.withOpacity(0.15),
              child: Icon(
                isCancelled ? Icons.close : Icons.directions_boat,
                color: isCancelled ? Colors.grey : AppTheme.harbourTeal,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${ride.pickupLabel} → ${ride.dropoffLabel}',
                      style: Theme.of(context).textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    '${formatDateTime(ride.createdAt)}'
                    '${partner.isNotEmpty ? ' • $partner' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isCancelled ? '—' : formatEur(ride.fareEur),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  ride.status.label,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
