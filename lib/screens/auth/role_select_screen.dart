import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/auth_service.dart';
import '../../theme.dart';
import '../shell/home_shell.dart';

class RoleSelectScreen extends StatefulWidget {
  const RoleSelectScreen({super.key, this.allowBack = false});

  final bool allowBack;

  @override
  State<RoleSelectScreen> createState() => _RoleSelectScreenState();
}

class _RoleSelectScreenState extends State<RoleSelectScreen> {
  UserRole _role = UserRole.passenger;
  final _vesselName = TextEditingController(text: 'My Boat');
  int _capacity = 6;

  @override
  void dispose() {
    _vesselName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthService>();
    await auth.updateProfile(
      role: _role,
      vesselName: _role == UserRole.driver ? _vesselName.text.trim() : null,
      vesselCapacity: _role == UserRole.driver ? _capacity : null,
    );
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('How will you use Boats?'),
        automaticallyImplyLeading: widget.allowBack,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _RoleCard(
                title: 'Passenger',
                subtitle: 'Book a boat across the harbour.',
                icon: Icons.person,
                selected: _role == UserRole.passenger,
                onTap: () => setState(() => _role = UserRole.passenger),
              ),
              const SizedBox(height: 12),
              _RoleCard(
                title: 'Driver',
                subtitle: 'Take passengers in your vessel.',
                icon: Icons.directions_boat_filled,
                selected: _role == UserRole.driver,
                onTap: () => setState(() => _role = UserRole.driver),
              ),
              if (_role == UserRole.driver) ...[
                const SizedBox(height: 24),
                const Text('Tell us about your boat'),
                const SizedBox(height: 8),
                TextField(
                  controller: _vesselName,
                  decoration: const InputDecoration(labelText: 'Vessel name'),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Passenger capacity'),
                    const Spacer(),
                    IconButton(
                      onPressed: _capacity > 1
                          ? () => setState(() => _capacity--)
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Text('$_capacity',
                        style: Theme.of(context).textTheme.titleLarge),
                    IconButton(
                      onPressed: _capacity < 20
                          ? () => setState(() => _capacity++)
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _save,
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppTheme.harbourTeal : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 36, color: AppTheme.harbourNavy),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: Theme.of(context).textTheme.titleMedium),
                  Text(subtitle,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: AppTheme.harbourTeal),
          ],
        ),
      ),
    );
  }
}
