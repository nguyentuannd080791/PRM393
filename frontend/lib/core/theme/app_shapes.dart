import 'package:flutter/material.dart';

/// Standard Material 3 Shape tokens and Touch Target constraints for Mini Social.
/// Complies with stitch_mini_social_ui_specification/mini_social/DESIGN.md.
/// All radii are strictly >= 8.0dp.
/// Touch targets are strictly >= 48x48dp (NFR-02).
class AppShapes {
  AppShapes._();

  // ---------------------------------------------------------------------------
  // Radii Tokens (>= 8dp)
  // ---------------------------------------------------------------------------
  static const double radiusSmall = 8.0;       // Inner sub-containers, small pills
  static const double radiusMedium = 12.0;     // Inputs, buttons (10-12dp)
  static const double radiusLarge = 16.0;      // Standard post cards (14-16dp), dialogs
  static const double radiusExtraLarge = 20.0; // Feature cards
  static const double radiusDialog = 24.0;     // Dialogs & bottom sheet top
  static const double radiusFull = 999.0;      // Circular avatars, pills (9999px)

  // ---------------------------------------------------------------------------
  // Contextual Semantic Radii Tokens (from DESIGN.md)
  // ---------------------------------------------------------------------------
  /// Buttons radius: 10-12dp (DESIGN.md: 10px radius)
  static const double radiusButton = 10.0;

  /// Input fields radius: 10-12dp (DESIGN.md: 10px radius)
  static const double radiusInput = 10.0;

  /// Post cards radius: 14-16dp (DESIGN.md: 14px-16px corner radius)
  static const double radiusCard = 14.0;

  /// Mini Social Brand Mark radius (DESIGN.md: 10px radius for 40x40 square)
  static const double radiusBrandMark = 10.0;

  /// Avatar circular radius (DESIGN.md: strictly circular 50%)
  static const double radiusAvatar = 999.0;

  /// Chip & Filter pills radius (DESIGN.md: full pill shape 9999px)
  static const double radiusChip = 999.0;

  // ---------------------------------------------------------------------------
  // Component Dimension Tokens (from DESIGN.md)
  // ---------------------------------------------------------------------------
  /// Mini Social Bottom Navigation Bar height (64dp from DESIGN.md)
  static const double bottomNavBarHeight = 64.0;

  /// Mini Social Top App Bar height (56dp from DESIGN.md)
  static const double appBarHeight = 56.0;

  // ---------------------------------------------------------------------------
  // Touch Target Tokens (NFR-02)
  // ---------------------------------------------------------------------------
  static const double minTouchTargetSize = 48.0;
  static const Size minInteractiveDimension = Size(minTouchTargetSize, minTouchTargetSize);
  static const Size buttonMinSize = Size(64.0, minTouchTargetSize);

  // ---------------------------------------------------------------------------
  // Pre-configured BorderRadius
  // ---------------------------------------------------------------------------
  static final BorderRadius roundedSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius roundedMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius roundedLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius roundedExtraLarge = BorderRadius.circular(radiusExtraLarge);
  static final BorderRadius roundedDialog = BorderRadius.circular(radiusDialog);
  static const BorderRadius roundedBottomSheet = BorderRadius.vertical(top: Radius.circular(radiusDialog));
  static final BorderRadius roundedFull = BorderRadius.circular(radiusFull);

  static final BorderRadius roundedButton = BorderRadius.circular(radiusButton);
  static final BorderRadius roundedInput = BorderRadius.circular(radiusInput);
  static final BorderRadius roundedCard = BorderRadius.circular(radiusCard);
  static final BorderRadius roundedBrandMark = BorderRadius.circular(radiusBrandMark);

  // ---------------------------------------------------------------------------
  // Pre-configured ShapeBorder
  // ---------------------------------------------------------------------------
  static final ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: roundedCard);
  static final ShapeBorder dialogShape = RoundedRectangleBorder(borderRadius: roundedDialog);
  static const ShapeBorder bottomSheetShape = RoundedRectangleBorder(borderRadius: roundedBottomSheet);
  static final OutlinedBorder buttonShape = RoundedRectangleBorder(borderRadius: roundedButton);
  static final OutlinedBorder chipShape = RoundedRectangleBorder(borderRadius: roundedFull);
}
