import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFF0D0D0D);
  static const surface = Color(0xFF1A1A1A);
  static const surface2 = Color(0xFF242424);
  static const border = Color(0xFF2C2C2C);

  static const urgent = Color(0xFFFF3B30);
  static const important = Color(0xFFFF9500);
  static const upcoming = Color(0xFF30D158);
  static const opportunity = Color(0xFF0A84FF);
  static const missed = Color(0xFFFF6961);

  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF8E8E93);
  static const textTertiary = Color(0xFF48484A);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.upcoming,
          surface: AppColors.surface,
          onSurface: AppColors.textPrimary,
        ),
        fontFamily: 'SF Pro Display',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: AppColors.textPrimary, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: -0.3),
          titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.5),
          labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 1.2),
        ),
        dividerColor: AppColors.border,
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: AppColors.surface,
          selectedItemColor: AppColors.textPrimary,
          unselectedItemColor: AppColors.textTertiary,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          elevation: 0,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.background,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
          iconTheme: IconThemeData(color: AppColors.textPrimary),
        ),
      );
}

Color priorityColor(String priority) {
  switch (priority) {
    case 'urgent': return AppColors.urgent;
    case 'important': return AppColors.important;
    case 'upcoming': return AppColors.upcoming;
    case 'opportunity': return AppColors.opportunity;
    case 'missed': return AppColors.missed;
    default: return AppColors.textTertiary;
  }
}

String priorityLabel(String priority) => priority.toUpperCase();
