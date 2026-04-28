import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/location_service.dart';
import 'services/ride_service.dart';
import 'theme.dart';

class BoatsApp extends StatelessWidget {
  const BoatsApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService(prefs)),
        ChangeNotifierProvider(create: (_) => RideService(prefs)),
        ChangeNotifierProvider(create: (_) => ChatService()),
        ChangeNotifierProvider(create: (_) => LocationService()),
      ],
      child: MaterialApp(
        title: 'Cork Harbour Boats',
        theme: AppTheme.light(),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      ),
    );
  }
}
