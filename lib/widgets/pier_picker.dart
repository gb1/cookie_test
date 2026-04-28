import 'package:flutter/material.dart';

import '../models/pier.dart';
import '../util/cork_harbour.dart';

/// Bottom-sheet style list of harbour piers. Returns the selected [Pier]
/// via Navigator.pop.
class PierPicker extends StatelessWidget {
  const PierPicker({super.key, required this.title});

  final String title;

  static Future<Pier?> show(BuildContext context, {required String title}) {
    return showModalBottomSheet<Pier>(
      context: context,
      showDragHandle: true,
      builder: (_) => PierPicker(title: title),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: CorkHarbour.piers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final pier = CorkHarbour.piers[i];
                return ListTile(
                  leading: const Icon(Icons.anchor),
                  title: Text(pier.name),
                  onTap: () => Navigator.of(context).pop(pier),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
