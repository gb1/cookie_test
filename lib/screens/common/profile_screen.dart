import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../services/ride_service.dart';
import '../../theme.dart';
import '../auth/role_select_screen.dart';
import '../auth/sign_in_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    final user = auth.currentUser;
    if (user == null) {
      return const Center(child: Text('Not signed in'));
    }

    return ListView(
      padding: const EdgeInsets.symmetric(vertical: 16),
      children: [
        const SizedBox(height: 8),
        Center(
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.harbourTeal.withOpacity(0.2),
            child: Text(
              _initials(user.name),
              style: const TextStyle(fontSize: 24, color: AppTheme.harbourNavy),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
            child: Text(user.name,
                style: Theme.of(context).textTheme.titleLarge)),
        Center(
            child: Text(user.email,
                style: Theme.of(context).textTheme.bodyMedium)),
        const SizedBox(height: 24),
        ListTile(
          leading: Icon(user.role == UserRole.driver
              ? Icons.directions_boat_filled
              : Icons.person),
          title: Text(user.role == UserRole.driver ? 'Driver' : 'Passenger'),
          subtitle: user.role == UserRole.driver
              ? Text(
                  '${user.vesselName ?? 'No vessel'} • '
                  '${user.vesselCapacity ?? 0} seats',
                )
              : const Text('Switch to driver mode in settings.'),
        ),
        ListTile(
          leading: const Icon(Icons.swap_horiz),
          title: const Text('Switch role / vessel'),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const RoleSelectScreen(allowBack: true),
              ),
            );
          },
        ),
        ListTile(
          leading: const Icon(Icons.delete_outline),
          title: const Text('Clear ride history'),
          onTap: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Clear history?'),
                content: const Text(
                    'This will remove your saved trips on this device.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            );
            if (confirm == true && context.mounted) {
              // The ride service does not expose a clear method publicly;
              // signing out + back in is the simplest demo route.
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Coming soon.')),
              );
            }
          },
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.logout),
          title: const Text('Sign out'),
          onTap: () async {
            final ride = context.read<RideService>();
            ride.setDriverOnline(user, online: false);
            await context.read<AuthService>().signOut();
            if (!context.mounted) return;
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute<void>(builder: (_) => const SignInScreen()),
              (_) => false,
            );
          },
        ),
      ],
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
