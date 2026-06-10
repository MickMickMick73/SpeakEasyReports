import 'package:flutter/material.dart';

/// Shared accent colors. For surfaces/text in themed widgets use [AppPalette.of].
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

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bg,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.text,
    required this.textMuted,
    required this.primary,
    required this.onPrimary,
    required this.success,
    required this.danger,
    required this.warning,
    required this.buttonSecondaryBg,
    required this.buttonSecondaryText,
    required this.buttonSecondaryBorder,
  });

  final Color bg;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color text;
  final Color textMuted;
  final Color primary;
  final Color onPrimary;
  final Color success;
  final Color danger;
  final Color warning;
  final Color buttonSecondaryBg;
  final Color buttonSecondaryText;
  final Color buttonSecondaryBorder;

  static AppPalette dark = const AppPalette(
    bg: Color(0xFF000000),
    surface: Color(0xFF121212),
    surfaceAlt: Color(0xFF1C1C1E),
    border: Color(0xFF3A3A3C),
    text: Color(0xFFF2F2F7),
    textMuted: Color(0xFF8E8E93),
    primary: Color(0xFF0A84FF),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF30D158),
    danger: Color(0xFFFF453A),
    warning: Color(0xFFFFD60A),
    buttonSecondaryBg: Color(0xFF1C1C1E),
    buttonSecondaryText: Color(0xFF0A84FF),
    buttonSecondaryBorder: Color(0xFF0A84FF),
  );

  static AppPalette light = const AppPalette(
    bg: Color(0xFFF2F2F7),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFE5E5EA),
    border: Color(0xFFC7C7CC),
    text: Color(0xFF0F172A),
    textMuted: Color(0xFF64748B),
    primary: Color(0xFF007AFF),
    onPrimary: Color(0xFFFFFFFF),
    success: Color(0xFF248A3D),
    danger: Color(0xFFD70015),
    warning: Color(0xFFB25000),
    buttonSecondaryBg: Color(0xFFFFFFFF),
    buttonSecondaryText: Color(0xFF007AFF),
    buttonSecondaryBorder: Color(0xFF007AFF),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? dark;

  @override
  AppPalette copyWith({
    Color? bg,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? text,
    Color? textMuted,
    Color? primary,
    Color? onPrimary,
    Color? success,
    Color? danger,
    Color? warning,
    Color? buttonSecondaryBg,
    Color? buttonSecondaryText,
    Color? buttonSecondaryBorder,
  }) {
    return AppPalette(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      text: text ?? this.text,
      textMuted: textMuted ?? this.textMuted,
      primary: primary ?? this.primary,
      onPrimary: onPrimary ?? this.onPrimary,
      success: success ?? this.success,
      danger: danger ?? this.danger,
      warning: warning ?? this.warning,
      buttonSecondaryBg: buttonSecondaryBg ?? this.buttonSecondaryBg,
      buttonSecondaryText: buttonSecondaryText ?? this.buttonSecondaryText,
      buttonSecondaryBorder: buttonSecondaryBorder ?? this.buttonSecondaryBorder,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return this;
  }
}

ThemeData buildAppTheme({required bool dark}) {
  final p = dark ? AppPalette.dark : AppPalette.light;

  return ThemeData(
    useMaterial3: true,
    brightness: dark ? Brightness.dark : Brightness.light,
    scaffoldBackgroundColor: p.bg,
    extensions: [p],
    colorScheme: ColorScheme.fromSeed(
      seedColor: p.primary,
      brightness: dark ? Brightness.dark : Brightness.light,
      surface: p.surface,
      onPrimary: p.onPrimary,
      primary: p.primary,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: p.surface,
      foregroundColor: p.text,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
    ),
    textTheme: TextTheme(
      headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: p.text),
      titleLarge: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: p.text),
      bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: p.text),
      bodyMedium: TextStyle(fontSize: 16, color: p.text),
      labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: p.text),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: p.surfaceAlt,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.border, width: 2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.border, width: 2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: p.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(56),
        backgroundColor: p.primary,
        foregroundColor: p.onPrimary,
        textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: p.buttonSecondaryText,
        side: BorderSide(color: p.buttonSecondaryBorder, width: 2),
        minimumSize: const Size.fromHeight(48),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: p.surface,
      indicatorColor: p.primary.withValues(alpha: 0.2),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: states.contains(WidgetState.selected) ? p.primary : p.textMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected) ? p.primary : p.textMuted,
        );
      }),
    ),
  );
}