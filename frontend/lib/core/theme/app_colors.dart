import 'package:flutter/material.dart';

/// Defines the color palette and Material 3 ColorSchemes for fb_clone.
/// Complies with Section IV.4.4 (no Meta #1877F2 copycat colors; uses neutral Royal Blue).
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand Primary & Accents (Distinct Royal Blue & Deep Indigo)
  // ---------------------------------------------------------------------------
  static const Color primaryLight = Color(0xFF2563EB); // Tailwind Royal Blue 600
  static const Color primaryDark = Color(0xFF60A5FA);  // Tailwind Blue 400
  static const Color primaryContainerLight = Color(0xFFDBEAFE);
  static const Color primaryContainerDark = Color(0xFF1E3A8A);

  static const Color secondaryLight = Color(0xFF64748B); // Slate 500
  static const Color secondaryDark = Color(0xFF94A3B8);  // Slate 400
  static const Color secondaryContainerLight = Color(0xFFF1F5F9);
  static const Color secondaryContainerDark = Color(0xFF334155);

  static const Color tertiaryLight = Color(0xFFDB2777); // Rose 600
  static const Color tertiaryDark = Color(0xFFF472B6);  // Rose 400

  // ---------------------------------------------------------------------------
  // Dark Surfaces (BR-21 Default: Deep Slate / OLED friendly)
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF121212);    // Baseline M3 dark surface
  static const Color darkCardSurface = Color(0xFF1E293B);// Slate 800 (Post cards)
  static const Color darkDialogSurface = Color(0xFF334155);// Slate 700
  static const Color darkTextPrimary = Color(0xFFE2E8F0);// High-contrast text (15.2:1)
  static const Color darkTextSecondary = Color(0xFF94A3B8);// Secondary text (7.3:1)
  static const Color darkBorder = Color(0xFF475569);     // Outlines & borders
  static const Color darkDivider = Color(0xFF334155);    // Subtle list dividers

  // ---------------------------------------------------------------------------
  // Light Surfaces
  // ---------------------------------------------------------------------------
  static const Color lightBackground = Color(0xFFF8FAFC);// Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);   // Pure white
  static const Color lightCardSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF0F172A);// Slate 900 (17.9:1)
  static const Color lightTextSecondary = Color(0xFF64748B);// Slate 500 (4.76:1)
  static const Color lightBorder = Color(0xFFCBD5E1);    // Slate 300
  static const Color lightDivider = Color(0xFFE2E8F0);   // Slate 200

  // ---------------------------------------------------------------------------
  // Semantic & Reaction Colors
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFDC2626);
  static const Color errorDark = Color(0xFFF87171);
  static const Color success = Color(0xFF16A34A);

  static const Color reactionLike = Color(0xFF2563EB); // Royal Blue
  static const Color reactionLove = Color(0xFFEF4444); // Red
  static const Color reactionHaha = Color(0xFFF59E0B); // Amber
  static const Color reactionWow = Color(0xFFF59E0B);  // Amber
  static const Color reactionSad = Color(0xFF3B82F6);  // Light Blue
  static const Color reactionAngry = Color(0xFFEA580C);// Deep Orange

  // ---------------------------------------------------------------------------
  // Material 3 Color Schemes
  // ---------------------------------------------------------------------------
  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: Color(0xFF003258),
    primaryContainer: primaryContainerDark,
    onPrimaryContainer: Color(0xFFDBEAFE),
    secondary: secondaryDark,
    onSecondary: Color(0xFF0F172A),
    secondaryContainer: secondaryContainerDark,
    onSecondaryContainer: Color(0xFFF1F5F9),
    tertiary: tertiaryDark,
    onTertiary: Color(0xFF4C0519),
    tertiaryContainer: Color(0xFF831843),
    onTertiaryContainer: Color(0xFFFCE7F3),
    error: errorDark,
    onError: Color(0xFF450A0A),
    errorContainer: Color(0xFF7F1D1D),
    onErrorContainer: Color(0xFFFEE2E2),
    surface: darkSurface,
    onSurface: darkTextPrimary,
    surfaceContainerLowest: Color(0xFF0A0F1D),
    surfaceContainerLow: darkBackground,
    surfaceContainer: darkCardSurface,
    surfaceContainerHigh: darkDialogSurface,
    surfaceContainerHighest: Color(0xFF475569),
    outline: darkBorder,
    outlineVariant: darkDivider,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );

  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: primaryContainerLight,
    onPrimaryContainer: Color(0xFF1E3A8A),
    secondary: secondaryLight,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: secondaryContainerLight,
    onSecondaryContainer: Color(0xFF0F172A),
    tertiary: tertiaryLight,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFFFCE7F3),
    onTertiaryContainer: Color(0xFF831843),
    error: error,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFEE2E2),
    onErrorContainer: Color(0xFF7F1D1D),
    surface: lightSurface,
    onSurface: lightTextPrimary,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: lightBackground,
    surfaceContainer: Color(0xFFF1F5F9),
    surfaceContainerHigh: Color(0xFFE2E8F0),
    surfaceContainerHighest: Color(0xFFCBD5E1),
    outline: lightBorder,
    outlineVariant: lightDivider,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
  );
}
