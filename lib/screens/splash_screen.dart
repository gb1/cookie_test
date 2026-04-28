import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/auth_service.dart';
import '../theme.dart';
import 'auth/sign_in_screen.dart';
import 'shell/home_shell.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    Future<void>.microtask(() {
      if (!context.mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) =>
              auth.isSignedIn ? const HomeShell() : const SignInScreen(),
        ),
      );
    });
    return const Scaffold(
      backgroundColor: AppTheme.harbourNavy,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.directions_boat, size: 72, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Cork Harbour Boats',
              style: TextStyle(color: Colors.white, fontSize: 22),
            ),
          ],
        ),
      ),
    );
  }
}
