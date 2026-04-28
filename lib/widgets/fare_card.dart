import 'package:flutter/material.dart';

import '../theme.dart';
import '../util/formatters.dart';

class FareCard extends StatelessWidget {
  const FareCard({
    super.key,
    required this.distanceKm,
    required this.duration,
    required this.fareEur,
  });

  final double distanceKm;
  final Duration duration;
  final double fareEur;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Estimate',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    formatEur(fareEur),
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppTheme.harbourNavy,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${formatKm(distanceKm)} • ${formatDuration(duration)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.directions_boat, size: 40, color: AppTheme.harbourTeal),
          ],
        ),
      ),
    );
  }
}
