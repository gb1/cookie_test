import 'package:flutter/material.dart';

import '../models/ride.dart';
import '../theme.dart';
import '../util/formatters.dart';

class RideRequestCard extends StatelessWidget {
  const RideRequestCard({
    super.key,
    required this.ride,
    required this.onAccept,
    required this.onDecline,
  });

  final Ride ride;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppTheme.harbourTeal.withOpacity(0.15),
                  child: const Icon(Icons.person, color: AppTheme.harbourNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ride.passengerName,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        formatDateTime(ride.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  formatEur(ride.fareEur),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.harbourNavy,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _RouteRow(label: 'Pickup', text: ride.pickupLabel, icon: Icons.flag),
            const SizedBox(height: 4),
            _RouteRow(
                label: 'Drop-off',
                text: ride.dropoffLabel,
                icon: Icons.location_on),
            const SizedBox(height: 8),
            Text(
              '${formatKm(ride.distanceKm)} • ${formatDuration(Duration(minutes: ride.etaMinutes))}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onDecline,
                    child: const Text('Pass'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({
    required this.label,
    required this.text,
    required this.icon,
  });

  final String label;
  final String text;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppTheme.harbourTeal),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: Theme.of(context).textTheme.bodyMedium,
              children: [
                TextSpan(
                  text: '$label: ',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: text),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
