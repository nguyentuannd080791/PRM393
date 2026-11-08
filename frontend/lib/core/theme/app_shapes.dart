import 'package:flutter/material.dart';

/// Standard Material 3 Shape tokens and Touch Target constraints.
/// All radii are strictly >= 8.0dp.
/// Touch targets are strictly >= 48x48dp (NFR-02).
class AppShapes {
  AppShapes._();

  // ---------------------------------------------------------------------------
  // Radii Tokens (>= 8dp)
  // ---------------------------------------------------------------------------
  static const double radiusSmall = 8.0;       // Badges, chips, reaction pills
  static const double radiusMedium = 12.0;     // Post cards, text fields, snackbars
  static const double radiusLarge = 16.0;      // Menus, popups
  static const double radiusExtraLarge = 20.0; // Buttons (Filled, Outlined)
  static const double radiusDialog = 24.0;     // Dialogs & bottom sheet top
  static const double radiusFull = 999.0;      // Avatars, pills

  // ---------------------------------------------------------------------------
  // Touch Target Tokens (NFR-02)
  // ---------------------------------------------------------------------------
  static const double minTouchTargetSize = 48.0;
  static const Size minInteractiveDimension = Size(minTouchTargetSize, minTouchTargetSize);
  static const Size buttonMinSize = Size(minTouchTargetSize, minTouchTargetSize);

  // ---------------------------------------------------------------------------
  // Pre-configured BorderRadius
  // ---------------------------------------------------------------------------
  static final BorderRadius roundedSmall = BorderRadius.circular(radiusSmall);
  static final BorderRadius roundedMedium = BorderRadius.circular(radiusMedium);
  static final BorderRadius roundedLarge = BorderRadius.circular(radiusLarge);
  static final BorderRadius roundedExtraLarge = BorderRadius.circular(radiusExtraLarge);
  static final BorderRadius roundedDialog = BorderRadius.circular(radiusDialog);
  static const BorderRadius roundedBottomSheet = BorderRadius.vertical(top: Radius.circular(radiusDialog));

  // ---------------------------------------------------------------------------
  // Pre-configured ShapeBorder
  // ---------------------------------------------------------------------------
  static final ShapeBorder cardShape = RoundedRectangleBorder(borderRadius: roundedMedium);
  static final ShapeBorder dialogShape = RoundedRectangleBorder(borderRadius: roundedDialog);
  static const ShapeBorder bottomSheetShape = RoundedRectangleBorder(borderRadius: roundedBottomSheet);
  static final OutlinedBorder buttonShape = RoundedRectangleBorder(borderRadius: roundedExtraLarge);
}
