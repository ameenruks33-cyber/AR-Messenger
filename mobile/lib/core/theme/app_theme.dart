import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const primary = Color(0xFF075E54);
  static const primaryDark = Color(0xFF054C44);
  static const teal = Color(0xFF128C7E);
  static const accent = Color(0xFF25D366);
  static const outgoing = Color(0xFFDCF8C6);
  static const incoming = Color(0xFFFFFFFF);
  static const chatBg = Color(0xFFECE5DD);
  static const surface = Color(0xFFF7F8FA);
  static const danger = Color(0xFFD32F2F);
  static const warning = Color(0xFFF9A825);
  static const muted = Color(0xFF667781);
}

class AppTheme {
  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.teal,
        brightness: Brightness.light,
      ),
    );

    return base.copyWith(
      textTheme: GoogleFonts.interTextTheme(base.textTheme),
      scaffoldBackgroundColor: Colors.white,
      navigationBarTheme: const NavigationBarThemeData(
        indicatorColor: Color(0x3325D366),
        backgroundColor: Colors.white,
        elevation: 3,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.teal,
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF0F2F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
