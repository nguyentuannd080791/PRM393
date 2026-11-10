import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Clean circular text-only avatar displaying 2-letter uppercase initials.
/// Complies with stitch_mini_social_ui_specification/mini_social/DESIGN.md.
/// Replaces raster images with deterministic initials over soft tinted surfaces (#EAF2FF).
class TextAvatar extends StatelessWidget {
  /// The user's full name or initials used to generate the 2-letter initials.
  final String name;

  /// Diameter of the circular avatar (default 38.0dp).
  /// Typical sizes: 28dp (replies), 38dp (feed cards), 48dp (profile/search), 76-80dp (hero profile).
  final double size;

  /// Background color fill (defaults to soft blue #EAF2FF).
  final Color? backgroundColor;

  /// Initials text color (defaults to signature blue #0866FF).
  final Color? textColor;

  /// Custom font size (defaults to proportional calculation based on size).
  final double? fontSize;

  /// Font weight of the initials (default FontWeight.w700).
  final FontWeight fontWeight;

  /// Whether to display a presence/online indicator dot on the bottom-right edge.
  final bool showOnlineIndicator;

  /// Presence indicator color (defaults to tertiary emerald #15966A).
  final Color onlineIndicatorColor;

  /// Whether to deterministically select a pastel background palette from name hash.
  final bool deterministicPalette;

  const TextAvatar({
    super.key,
    required this.name,
    this.size = 38.0,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.fontWeight = FontWeight.w700,
    this.showOnlineIndicator = false,
    this.onlineIndicatorColor = AppColors.success,
    this.deterministicPalette = false,
  });

  /// Extracts 1-2 uppercase initials from a full name.
  /// Examples:
  /// - "An Nguyen" -> "AN"
  /// - "John Doe" -> "JD"
  /// - "Minh" -> "MI"
  /// - "A" -> "A"
  /// - "" -> "M"
  static String extractInitials(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'M';
    }
    final trimmed = name.trim();
    final parts = trimmed.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();

    if (parts.length >= 2) {
      final first = parts.first[0].toUpperCase();
      final last = parts.last[0].toUpperCase();
      return '$first$last';
    }

    final single = parts.first;
    if (single.length >= 2) {
      return single.substring(0, 2).toUpperCase();
    }
    return single.toUpperCase();
  }

  /// Pastel avatar container palettes from Mini Social specification.
  static const List<(Color bg, Color text)> pastelPalettes = [
    (AppColors.softBlueSurface, AppColors.primaryLight),      // Soft Blue
    (AppColors.avatarAmberBg, AppColors.avatarAmberText),       // Soft Amber
    (AppColors.avatarBlueBg, AppColors.avatarBlueText),         // Soft Light Blue
    (AppColors.avatarPinkBg, AppColors.avatarPinkText),         // Soft Pink
    (AppColors.avatarEmeraldBg, AppColors.avatarEmeraldText),   // Soft Emerald
    (AppColors.avatarIndigoBg, AppColors.avatarIndigoText),     // Soft Indigo
    (AppColors.avatarSlateBg, AppColors.avatarSlateText),       // Soft Slate
  ];

  /// Deterministically picks a pastel palette based on name hash.
  static (Color bg, Color text) paletteForName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return pastelPalettes.first;
    }
    final index = name.trim().hashCode.abs() % pastelPalettes.length;
    return pastelPalettes[index];
  }

  @override
  Widget build(BuildContext context) {
    final initials = extractInitials(name);
    final (Color defaultBg, Color defaultText) = deterministicPalette
        ? paletteForName(name)
        : (AppColors.softBlueSurface, AppColors.primaryLight);

    final resolvedBg = backgroundColor ?? defaultBg;
    final resolvedText = textColor ?? defaultText;
    final resolvedFontSize = fontSize ?? (size * 0.40).clamp(10.0, 32.0);
    final indicatorSize = (size * 0.28).clamp(8.0, 20.0);
    final indicatorBorderWidth = (size * 0.05).clamp(1.5, 3.0);

    return Semantics(
      label: 'Avatar of $name',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: resolvedBg,
              ),
              alignment: Alignment.center,
              child: Text(
                initials,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFamilyFallback: AppTypography.fontFamilyFallback,
                  fontSize: resolvedFontSize,
                  fontWeight: fontWeight,
                  color: resolvedText,
                  height: 1.0,
                  letterSpacing: 0.0,
                ),
              ),
            ),
            if (showOnlineIndicator)
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: indicatorSize,
                  height: indicatorSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: onlineIndicatorColor,
                    border: Border.all(
                      color: Colors.white,
                      width: indicatorBorderWidth,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
