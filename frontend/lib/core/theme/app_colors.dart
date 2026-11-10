import 'package:flutter/material.dart';

/// Defines the color palette and Material 3 ColorSchemes for Mini Social.
/// Complies with stitch_mini_social_ui_specification/mini_social/DESIGN.md.
/// Complies with Section IV.4.4 (no Meta #1877F2 copycat colors).
class AppColors {
  AppColors._();

  // ---------------------------------------------------------------------------
  // Brand Primary & Accents (Mini Social Action Blue & M3 Primary)
  // ---------------------------------------------------------------------------
  /// Signature action blue: buttons, focus rings, active navigation items (#0866FF)
  static const Color primaryAction = Color(0xFF0866FF);
  static const Color primaryPressed = Color(0xFF0652CC);

  /// Material 3 primary key color token (#0050CD)
  static const Color primaryM3 = Color(0xFF0050CD);

  /// Primary color token for light theme (Mini Social signature action blue)
  static const Color primaryLight = Color(0xFF0866FF);

  /// Primary color token for dark theme (Inverse primary / fixed dim)
  static const Color primaryDark = Color(0xFFB3C5FF);

  /// Primary container tokens
  static const Color primaryContainer = Color(0xFF0866FF);
  static const Color primaryContainerLight = Color(0xFF0866FF);
  static const Color primaryContainerDark = Color(0xFF003FA5);
  static const Color primaryFixed = Color(0xFFDBE1FF);
  static const Color primaryFixedDim = Color(0xFFB3C5FF);

  // ---------------------------------------------------------------------------
  // Secondary Tokens (M3 Secondary, Slate metadata, Soft Containers)
  // ---------------------------------------------------------------------------
  static const Color secondaryLight = Color(0xFF575F6A); // Spec M3 secondary
  static const Color secondaryDark = Color(0xFFBFC7D4);
  static const Color secondaryContainer = Color(0xFFDBE3F0); // Soft tinted container
  static const Color secondaryContainerLight = Color(0xFFDBE3F0);
  static const Color secondaryContainerDark = Color(0xFF334155);
  static const Color secondaryFixed = Color(0xFFDBE3F0);
  static const Color secondaryFixedDim = Color(0xFFBFC7D4);

  // ---------------------------------------------------------------------------
  // Soft Blue & Category Surfaces
  // ---------------------------------------------------------------------------
  /// Delicate high-tint blue container fill: category chips, active tab badges, avatar fill (#EAF2FF)
  static const Color softBlueSurface = Color(0xFFEAF2FF);

  // ---------------------------------------------------------------------------
  // Tertiary & Success Tokens (Organic Emerald Green)
  // ---------------------------------------------------------------------------
  static const Color tertiaryLight = Color(0xFF15966A); // Confirmation / Success
  static const Color tertiaryDark = Color(0xFF6BDBA9);
  static const Color tertiaryContainer = Color(0xFF00825A);
  static const Color tertiaryContainerLight = Color(0xFFE1FFEC);
  static const Color tertiaryFixed = Color(0xFF88F8C4);
  static const Color tertiaryFixedDim = Color(0xFF6BDBA9);
  static const Color success = Color(0xFF15966A);

  // ---------------------------------------------------------------------------
  // Error & Destructive Tokens (Crisp Semantic Red)
  // ---------------------------------------------------------------------------
  static const Color error = Color(0xFFBA1A1A);
  static const Color errorDark = Color(0xFFFFB4AB);
  static const Color errorContainer = Color(0xFFFFDAD6);
  static const Color destructive = Color(0xFFD92D20); // Action deletions / red alerts

  // ---------------------------------------------------------------------------
  // Text & Slate Scale
  // ---------------------------------------------------------------------------
  /// High-readability deep slate for headlines, authors, and post body (#121C2A)
  static const Color slate900 = Color(0xFF121C2A);
  static const Color slate800 = Color(0xFF182230);
  /// Secondary text, metadata, timestamps, subtle engagement numbers (#667085)
  static const Color slate600 = Color(0xFF667085);
  static const Color slate500 = Color(0xFF727687);
  static const Color slate400 = Color(0xFF94A3B8);

  // ---------------------------------------------------------------------------
  // Borders & Dividers
  // ---------------------------------------------------------------------------
  /// Crisp hair-line divider separating content blocks (#E4EAF2)
  static const Color divider = Color(0xFFE4EAF2);
  /// Outline variant / subtle card border (#C2C6D8)
  static const Color border = Color(0xFFC2C6D8);
  static const Color outline = Color(0xFF727687);
  static const Color outlineVariant = Color(0xFFC2C6D8);

  // ---------------------------------------------------------------------------
  // Light Surfaces (Canvas & Elevated Cards)
  // ---------------------------------------------------------------------------
  /// Cool-tinted page background (#F8F9FF)
  static const Color lightBackground = Color(0xFFF8F9FF);
  static const Color surfaceLight = Color(0xFFF8F9FF);
  /// Pure white surface: elevated cards, bottom sheets, input modules (#FFFFFF)
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardSurface = Color(0xFFFFFFFF);
  static const Color lightTextPrimary = Color(0xFF121C2A);
  static const Color lightTextSecondary = Color(0xFF667085);
  static const Color lightBorder = Color(0xFFC2C6D8);
  static const Color lightDivider = Color(0xFFE4EAF2);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFEFF3FF);
  static const Color surfaceContainer = Color(0xFFE6EEFF);
  static const Color surfaceContainerHigh = Color(0xFFDFE9FC);
  static const Color surfaceContainerHighest = Color(0xFFD9E3F6);

  // ---------------------------------------------------------------------------
  // Dark Surfaces (Deep Slate / OLED friendly)
  // ---------------------------------------------------------------------------
  static const Color darkBackground = Color(0xFF121C2A);
  static const Color darkSurface = Color(0xFF182230);
  static const Color darkCardSurface = Color(0xFF273140); // Inverse surface in spec
  static const Color darkDialogSurface = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFEBF1FF); // Inverse on surface
  static const Color darkTextSecondary = Color(0xFFC2C6D8);
  static const Color darkBorder = Color(0xFF424656);
  static const Color darkDivider = Color(0xFF273140);

  // ---------------------------------------------------------------------------
  // Semantic & Reaction Colors
  // ---------------------------------------------------------------------------
  static const Color reactionLike = Color(0xFF0866FF); // Action Blue
  static const Color reactionLove = Color(0xFFD92D20); // Destructive Red
  static const Color reactionHaha = Color(0xFFF59E0B); // Amber
  static const Color reactionWow = Color(0xFFF59E0B);  // Amber
  static const Color reactionSad = Color(0xFF3B82F6);  // Light Blue
  static const Color reactionAngry = Color(0xFFEA580C);// Deep Orange

  // ---------------------------------------------------------------------------
  // Deterministic Avatar Pastel Container Palette
  // ---------------------------------------------------------------------------
  static const Color avatarAmberBg = Color(0xFFFEF0C7);
  static const Color avatarAmberText = Color(0xFFB54708);

  static const Color avatarBlueBg = Color(0xFFE0F2FE);
  static const Color avatarBlueText = Color(0xFF0284C7);

  static const Color avatarPinkBg = Color(0xFFFCE7F3);
  static const Color avatarPinkText = Color(0xFFBE185D);

  static const Color avatarEmeraldBg = Color(0xFFECFDF5);
  static const Color avatarEmeraldText = Color(0xFF047857);

  static const Color avatarIndigoBg = Color(0xFFDBE1FF);
  static const Color avatarIndigoText = Color(0xFF0866FF);

  static const Color avatarSlateBg = Color(0xFFDBE3F0);
  static const Color avatarSlateText = Color(0xFF141C25);

  // ---------------------------------------------------------------------------
  // Material 3 Color Schemes
  // ---------------------------------------------------------------------------
  static const ColorScheme lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: primaryLight,
    onPrimary: Color(0xFFFFFFFF),
    primaryContainer: primaryContainerLight,
    onPrimaryContainer: Color(0xFFF9F7FF),
    secondary: secondaryLight,
    onSecondary: Color(0xFFFFFFFF),
    secondaryContainer: secondaryContainerLight,
    onSecondaryContainer: Color(0xFF5D6570),
    tertiary: tertiaryLight,
    onTertiary: Color(0xFFFFFFFF),
    tertiaryContainer: Color(0xFF00825A),
    onTertiaryContainer: Color(0xFFE1FFEC),
    error: error,
    onError: Color(0xFFFFFFFF),
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF93000A),
    surface: lightSurface,
    onSurface: slate900,
    onSurfaceVariant: slate600,
    surfaceContainerLowest: surfaceContainerLowest,
    surfaceContainerLow: surfaceContainerLow,
    surfaceContainer: surfaceContainer,
    surfaceContainerHigh: surfaceContainerHigh,
    surfaceContainerHighest: surfaceContainerHighest,
    outline: outline,
    outlineVariant: outlineVariant,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFF273140),
    onInverseSurface: Color(0xFFEBF1FF),
    inversePrimary: Color(0xFFB3C5FF),
    surfaceTint: Color(0xFF0054D7),
  );

  static const ColorScheme darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: primaryDark,
    onPrimary: Color(0xFF002B73),
    primaryContainer: primaryContainerDark,
    onPrimaryContainer: Color(0xFFDBE1FF),
    secondary: secondaryDark,
    onSecondary: Color(0xFF141C25),
    secondaryContainer: secondaryContainerDark,
    onSecondaryContainer: Color(0xFFDBE3F0),
    tertiary: tertiaryDark,
    onTertiary: Color(0xFF003823),
    tertiaryContainer: Color(0xFF005137),
    onTertiaryContainer: Color(0xFF88F8C4),
    error: errorDark,
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    surface: darkSurface,
    onSurface: darkTextPrimary,
    onSurfaceVariant: darkTextSecondary,
    surfaceContainerLowest: Color(0xFF0C131D),
    surfaceContainerLow: darkBackground,
    surfaceContainer: darkCardSurface,
    surfaceContainerHigh: darkDialogSurface,
    surfaceContainerHighest: Color(0xFF475569),
    outline: darkBorder,
    outlineVariant: darkDivider,
    shadow: Color(0xFF000000),
    scrim: Color(0xFF000000),
    inverseSurface: Color(0xFFF8F9FF),
    onInverseSurface: Color(0xFF121C2A),
    inversePrimary: Color(0xFF0050CD),
    surfaceTint: Color(0xFF0054D7),
  );
}
