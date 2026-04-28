import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  static const Color harbourNavy = Color(0xFF0B2F4A);
  static const Color harbourTeal = Color(0xFF1E7A8C);
  static const Color buoyAmber = Color(0xFFF4A300);
  static const Color foam = Color(0xFFF3F7FA);

  static ThemeData light() {
    final base = ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: harbourTeal,
        primary: harbourNavy,
        secondary: buoyAmber,
        surface: Colors.white,
      ),
      useMaterial3: true,
      scaffoldBackgroundColor: foam,
    );
    return base.copyWith(
      appBarTheme: const AppBarTheme(
        backgroundColor: harbourNavy,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
