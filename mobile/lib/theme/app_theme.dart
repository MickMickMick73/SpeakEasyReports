import 'package:flutter/material.dart';

class AppColors {
  static const bg = Color(0xFF000000);
  static const surface = Color(0xFF121212);
  static const surfaceAlt = Color(0xFF1C1C1E);
  static const border = Color(0xFF3A3A3C);
  static const text = Color(0xFFF2F2F7);
  static const textMuted = Color(0xFF8E8E93);
  static const primary = Color(0xFF0A84FF);
  static const success = Color(0xFF30D158);
  static const danger = Color(0xFFFF453A);
  static const warning = Color(0xFFFFD60A);
}

ThemeData buildAppTheme({required bool dark}) {
  final base = dark ? AppColors.bg : const Color(0xFFF2F2F7);
  final surface = dark ? AppColors.surface : Colors.white;
  final text = dark ? AppColors.text : const Color(0xFF0F172A);

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: base,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: surface,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: surface,
      foregroundColor: text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text),
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: text),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: text),
      bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: text),
      bodyMedium: TextStyle(fontSize: 16, color: text),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? AppColors.surfaceAlt : Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border, width: 2)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border, width: 2)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}