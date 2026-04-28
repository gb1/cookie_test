import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'screens/splash_screen.dart';
import 'services/auth_service.dart';
import 'services/chat_service.dart';
import 'services/location_service.dart';
import 'services/ride_service.dart';
import 'theme.dart';

class BoatsApp extends StatelessWidget {
  const BoatsApp({super.key, required this.client});

  final SupabaseClient client;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthService>(
          create: (_) => AuthService(client),
        ),
        ChangeNotifierProxyProvider<AuthService, RideService>(
          create: (ctx) => RideService(
            client: client,
            auth: ctx.read<AuthService>(),
          ),
          update: (_, __, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<AuthService, ChatService>(
          create: (ctx) => ChatService(
            client: client,
            auth: ctx.read<AuthService>(),
          ),
          update: (_, __, previous) => previous!,
        ),
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
