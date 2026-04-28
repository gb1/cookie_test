import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/app_user.dart';
import '../../services/ride_service.dart';
import '../../state/session.dart';
import '../common/chat_screen.dart';
import '../common/profile_screen.dart';
import '../common/ride_history_screen.dart';
import '../driver/driver_home_screen.dart';
import '../passenger/passenger_home_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final user = Session.require(context);
    final isDriver = user.role == UserRole.driver;

    final pages = <Widget>[
      isDriver ? const DriverHomeScreen() : const PassengerHomeScreen(),
      const RideHistoryScreen(),
      const _ChatTab(),
      const ProfileScreen(),
    ];

    final titles = <String>['Home', 'History', 'Chat', 'Profile'];

    return Scaffold(
      appBar: AppBar(
        title: Text('${titles[_index]} • ${isDriver ? 'Driver' : 'Passenger'}'),
      ),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.history), label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          NavigationDestination(
              icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}

class _ChatTab extends StatelessWidget {
  const _ChatTab();

  @override
  Widget build(BuildContext context) {
    final user = Session.require(context);
    final rides = context.watch<RideService>();
    final active = rides.activeFor(user.id);
    if (active != null) {
      return ChatScreen(ride: active);
    }
    // Fall back to the most recent ride that had a driver assigned.
    final lastWithDriver = rides
        .historyFor(user.id)
        .where((r) => r.driverId != null)
        .toList();
    if (lastWithDriver.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Chat is available once you have an active or completed trip.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return ChatScreen(ride: lastWithDriver.first);
  }
}
