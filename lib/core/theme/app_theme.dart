import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  AppColors._();

  static const Color background = Color(0xFF0A0714);
  static const Color backgroundLight = Color(0xFF13101F);
  static const Color surface = Color(0xFF1A1629);

  static const Color violet = Color(0xFF6D28D9);
  static const Color teal = Color(0xFF14B8A6);

  static const Color textPrimary = Color(0xFFF5F3FF);
  static const Color textSecondary = Color(0xFFA5A0C0);
  static const Color textTertiary = Color(0xFF6B6584);

  static const Color positive = Color(0xFF5EEAD4);
  static const Color negative = Color(0xFFFB7185);
  static const Color warning = Color(0xFFFBBF24);

  static const Color glassBorder = Color(0x24FFFFFF);
  static const Color glassBackground = Color(0x1FFFFFFF);
  static const Color glassHighlight = Color(0x99FFFFFF);

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient mintGradient = LinearGradient(
    colors: [Color(0xFF5EEAD4), Color(0xFF14B8A6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient coralGradient = LinearGradient(
    colors: [Color(0xFFFB7185), Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

class AppTheme {
  AppTheme._();

  static ThemeData get dark {
    final textTheme = GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.violet,
        secondary: AppColors.teal,
        surface: AppColors.surface,
        error: AppColors.negative,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.white.withValues(alpha: 0.16),
      ),
    );
  }
}
