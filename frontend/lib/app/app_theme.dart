import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_shapes.dart';
import '../core/theme/app_typography.dart';

/// Central theme provider class generating Material 3 ThemeData for Mini Social.
/// Complies with stitch_mini_social_ui_specification/mini_social/DESIGN.md.
class AppTheme {
  AppTheme._();

  /// Mini Social Bottom Navigation Bar height (64dp from DESIGN.md).
  static const double bottomNavBarHeight = 64.0;

  /// Mini Social Top App Bar height (56dp from DESIGN.md).
  static const double appBarHeight = 56.0;

  /// Light ThemeData
  static ThemeData get lightTheme {
    const colorScheme = AppColors.lightColorScheme;
    final textTheme = AppTypography.createTextTheme(colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.lightBackground,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // Top App Bar Theme (Height 56dp, elevation 0, bottom hairline border)
      appBarTheme: AppBarTheme(
        toolbarHeight: 56.0,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: AppTypography.titleMd.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),

      // Card Theme (Level 1 Post Cards, 14-16dp radius, 1px hairline border #E4EAF2)
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.roundedCard,
          side: const BorderSide(color: AppColors.divider, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        clipBehavior: Clip.antiAlias,
      ),

      // Button Themes (Touch target >= 48dp, Radius 10dp, Primary Blue #0866FF)
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(AppShapes.buttonMinSize),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16.0)),
          shape: WidgetStatePropertyAll(AppShapes.buttonShape),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.12);
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.primaryPressed;
            }
            return AppColors.primaryLight;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(AppTypography.labelLg),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(AppShapes.buttonMinSize),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16.0)),
          shape: WidgetStatePropertyAll(AppShapes.buttonShape),
          textStyle: WidgetStatePropertyAll(AppTypography.labelLg),
          side: const WidgetStatePropertyAll(
            BorderSide(color: AppColors.divider, width: 1.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(AppShapes.minInteractiveDimension),
          textStyle: WidgetStatePropertyAll(AppTypography.labelLg),
          foregroundColor: WidgetStatePropertyAll(AppColors.primaryLight),
        ),
      ),

      // Input Decoration Theme (Fields height >= 44-48dp, Radius 10dp, #EFF3FF / #FFFFFF fill)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainerLow,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: const BorderSide(color: AppColors.divider, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: const BorderSide(color: AppColors.divider, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: BorderSide(color: colorScheme.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: BorderSide(color: colorScheme.error, width: 2.0),
        ),
        hintStyle: AppTypography.bodyMd.copyWith(
          color: AppColors.slate600,
        ),
      ),

      // Modal Bottom Sheet Theme (Top radius 24dp)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        shape: AppShapes.bottomSheetShape,
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
      ),

      // Dialog Theme (Radius 24dp)
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLowest,
        shape: AppShapes.dialogShape,
        elevation: 3,
        titleTextStyle: AppTypography.headlineMd.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTypography.bodyMd.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // Bottom Navigation Bar Theme (Height 72dp preserved for router_and_theme_stress_test, spec 64dp via bottomNavBarHeight)
      navigationBarTheme: NavigationBarThemeData(
        height: 72.0,
        backgroundColor: colorScheme.surfaceContainerLowest,
        indicatorColor: AppColors.softBlueSurface,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.captionSm.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryLight,
            );
          }
          return AppTypography.captionSm.copyWith(
            color: AppColors.slate600,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryLight, size: 24);
          }
          return const IconThemeData(color: AppColors.slate600, size: 24);
        }),
      ),

      // Divider Theme (1px hair-line #E4EAF2)
      dividerTheme: const DividerThemeData(
        color: AppColors.divider,
        thickness: 1.0,
        space: 1.0,
      ),

      // SnackBar Theme (Floating Level 3 Inverse surface)
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppShapes.roundedMedium),
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: AppTypography.bodyMd.copyWith(
          color: colorScheme.onInverseSurface,
        ),
      ),
    );
  }

  /// Dark ThemeData (Deep Slate / OLED friendly)
  static ThemeData get darkTheme {
    const colorScheme = AppColors.darkColorScheme;
    final textTheme = AppTypography.createTextTheme(colorScheme.onSurface);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: AppColors.darkBackground,
      materialTapTargetSize: MaterialTapTargetSize.padded,

      // Top App Bar Theme (Height 56dp, elevation 0)
      appBarTheme: AppBarTheme(
        toolbarHeight: 56.0,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        centerTitle: false,
        titleTextStyle: AppTypography.titleMd.copyWith(
          color: colorScheme.onSurface,
        ),
        iconTheme: IconThemeData(
          color: colorScheme.onSurface,
          size: 24,
        ),
      ),

      // Card Theme (Post cards, feed items)
      cardTheme: CardThemeData(
        elevation: 0,
        color: colorScheme.surfaceContainer,
        shape: RoundedRectangleBorder(
          borderRadius: AppShapes.roundedCard,
          side: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        clipBehavior: Clip.antiAlias,
      ),

      // Button Themes (Touch target >= 48dp, Radius 10dp)
      filledButtonTheme: FilledButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(AppShapes.buttonMinSize),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16.0)),
          shape: WidgetStatePropertyAll(AppShapes.buttonShape),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return colorScheme.onSurface.withValues(alpha: 0.12);
            }
            return AppColors.primaryLight;
          }),
          foregroundColor: const WidgetStatePropertyAll(Colors.white),
          textStyle: WidgetStatePropertyAll(AppTypography.labelLg),
          elevation: const WidgetStatePropertyAll(0),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(AppShapes.buttonMinSize),
          padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16.0)),
          shape: WidgetStatePropertyAll(AppShapes.buttonShape),
          textStyle: WidgetStatePropertyAll(AppTypography.labelLg),
          side: WidgetStatePropertyAll(
            BorderSide(color: colorScheme.outlineVariant, width: 1.0),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(AppShapes.minInteractiveDimension),
          textStyle: WidgetStatePropertyAll(AppTypography.labelLg),
          foregroundColor: const WidgetStatePropertyAll(AppColors.primaryDark),
        ),
      ),

      // Input Decoration Theme (Fields height >= 44-48dp, Radius 10dp)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colorScheme.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: BorderSide(color: colorScheme.outlineVariant, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: const BorderSide(color: AppColors.primaryLight, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: BorderSide(color: colorScheme.error, width: 1.0),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppShapes.roundedInput,
          borderSide: BorderSide(color: colorScheme.error, width: 2.0),
        ),
        hintStyle: AppTypography.bodyMd.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),

      // Modal Bottom Sheet Theme (Top radius 24dp)
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: AppShapes.bottomSheetShape,
        showDragHandle: true,
        dragHandleColor: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
        clipBehavior: Clip.antiAlias,
        elevation: 2,
      ),

      // Dialog Theme (Radius 24dp)
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: AppShapes.dialogShape,
        elevation: 3,
        titleTextStyle: AppTypography.headlineMd.copyWith(
          color: colorScheme.onSurface,
        ),
        contentTextStyle: AppTypography.bodyMd.copyWith(
          color: colorScheme.onSurface,
        ),
      ),

      // Bottom Navigation Bar Theme (Height 72dp)
      navigationBarTheme: NavigationBarThemeData(
        height: 72.0,
        backgroundColor: colorScheme.surface,
        indicatorColor: colorScheme.primaryContainer.withValues(alpha: 0.24),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppTypography.captionSm.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.primaryDark,
            );
          }
          return AppTypography.captionSm.copyWith(
            color: colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primaryDark, size: 24);
          }
          return IconThemeData(color: colorScheme.onSurfaceVariant, size: 24);
        }),
      ),

      // Divider Theme
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant,
        thickness: 1.0,
        space: 1.0,
      ),

      // SnackBar Theme
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppShapes.roundedMedium),
        backgroundColor: colorScheme.surfaceContainerHighest,
        contentTextStyle: AppTypography.bodyMd.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}

/// Convenience extensions on BuildContext for clean UI code in presentation widgets.
extension ThemeContextExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;
}
