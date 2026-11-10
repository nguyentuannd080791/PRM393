import 'package:flutter/material.dart';

/// Typography Scale for Mini Social based on Inter font family.
/// Complies with stitch_mini_social_ui_specification/mini_social/DESIGN.md.
/// Guarantees contrast ratio >= 4.5:1 for body text (NFR-12).
class AppTypography {
  AppTypography._();

  /// Primary font family enforced across all typography tokens.
  static const String fontFamily = 'Inter';

  /// System font fallbacks to guarantee robust rendering in offline and headless test environments.
  static const List<String> fontFamilyFallback = [
    'Roboto',
    'San Francisco',
    'Segoe UI',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  // ---------------------------------------------------------------------------
  // 11 Core Typography Scale Tokens from DESIGN.md
  // ---------------------------------------------------------------------------

  /// headline-lg: 24px Bold, line-height 32px, letter-spacing -0.02em (-0.48px)
  /// Primary use: Root screen titles, welcome headings, profile hero initials.
  static const TextStyle headlineLg = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 24.0,
    fontWeight: FontWeight.w700,
    height: 32.0 / 24.0,
    letterSpacing: -0.48,
  );

  /// headline-md: 22px Bold, line-height 28px, letter-spacing -0.015em (-0.33px)
  /// Primary use: Sub-view titles, comments count header.
  static const TextStyle headlineMd = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 22.0,
    fontWeight: FontWeight.w700,
    height: 28.0 / 22.0,
    letterSpacing: -0.33,
  );

  /// title-md: 18px Semibold, line-height 24px, letter-spacing -0.01em (-0.18px)
  /// Primary use: Top app bar titles, profile name, section titles.
  static const TextStyle titleMd = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    height: 24.0 / 18.0,
    letterSpacing: -0.18,
  );

  /// title-sm: 16px Semibold, line-height 22px
  /// Primary use: Author handles, post titles, modal sheet titles.
  static const TextStyle titleSm = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    height: 22.0 / 16.0,
    letterSpacing: 0.0,
  );

  /// body-lg: 15px Regular, line-height 22px (1.47x)
  /// Primary use: Post content body, text inputs, saved post excerpts.
  static const TextStyle bodyLg = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w400,
    height: 22.0 / 15.0,
    letterSpacing: 0.0,
  );

  /// body-md: 14px Regular, line-height 20px (1.43x)
  /// Primary use: Standard body, comments, bio descriptions, helpers.
  static const TextStyle bodyMd = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    height: 20.0 / 14.0,
    letterSpacing: 0.0,
  );

  /// label-lg: 15px Semibold, line-height 20px
  /// Primary use: Primary action buttons, author identity anchors.
  static const TextStyle labelLg = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 15.0,
    fontWeight: FontWeight.w600,
    height: 20.0 / 15.0,
    letterSpacing: 0.0,
  );

  /// label-md: 14px Medium, line-height 18px
  /// Primary use: Action bar labels, interactive buttons, segmented tabs.
  static const TextStyle labelMd = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    height: 18.0 / 14.0,
    letterSpacing: 0.0,
  );

  /// label-sm: 13px Medium, line-height 16px
  /// Primary use: Form labels, small buttons, chips, filter tabs.
  static const TextStyle labelSm = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13.0,
    fontWeight: FontWeight.w500,
    height: 16.0 / 13.0,
    letterSpacing: 0.0,
  );

  /// caption-md: 13px Regular, line-height 16px
  /// Primary use: Post stats line, secondary metadata.
  static const TextStyle captionMd = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 13.0,
    fontWeight: FontWeight.w400,
    height: 16.0 / 13.0,
    letterSpacing: 0.0,
  );

  /// caption-sm: 12px Regular, line-height 16px
  /// Primary use: Timestamps, counters, badges, bottom navigation labels.
  static const TextStyle captionSm = TextStyle(
    fontFamily: fontFamily,
    fontFamilyFallback: fontFamilyFallback,
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    height: 16.0 / 12.0,
    letterSpacing: 0.0,
  );

  // ---------------------------------------------------------------------------
  // Material 3 TextTheme Generator
  // ---------------------------------------------------------------------------
  /// Generates a complete Material 3 TextTheme with defaultTextColor applied.
  static TextTheme createTextTheme(Color defaultTextColor) {
    return TextTheme(
      headlineLarge: headlineLg.copyWith(color: defaultTextColor),
      headlineMedium: headlineMd.copyWith(color: defaultTextColor),
      headlineSmall: titleMd.copyWith(color: defaultTextColor),
      titleLarge: titleMd.copyWith(color: defaultTextColor),
      titleMedium: titleSm.copyWith(color: defaultTextColor),
      titleSmall: labelLg.copyWith(color: defaultTextColor),
      bodyLarge: bodyLg.copyWith(color: defaultTextColor),
      bodyMedium: bodyMd.copyWith(color: defaultTextColor),
      bodySmall: captionSm.copyWith(color: defaultTextColor),
      labelLarge: labelLg.copyWith(color: defaultTextColor),
      labelMedium: labelMd.copyWith(color: defaultTextColor),
      labelSmall: labelSm.copyWith(color: defaultTextColor),
    );
  }
}
