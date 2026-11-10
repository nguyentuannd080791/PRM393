import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_shapes.dart';
import '../theme/app_typography.dart';

/// The official Mini Social Brand Mark.
/// Complies with stitch_mini_social_ui_specification/mini_social/DESIGN.md:
/// A solid blue (#0866FF) rounded square (10dp radius for 40x40dp standard size)
/// housing a centered, stylized white letter 'M'.
class MiniSocialBrandMark extends StatelessWidget {
  /// Dimension of the square brand mark (default 40.0dp).
  /// Spec variants: 40dp (top app bar), 56dp (scr17 register), 64dp (scr16 login).
  final double size;

  /// Corner radius of the rounded square (defaults to proportional 10dp at 40dp size).
  final double? borderRadius;

  /// Background color fill (defaults to #0866FF signature action blue).
  final Color backgroundColor;

  /// Color of the centered letter 'M' (defaults to white).
  final Color letterColor;

  /// Whether to display an active presence dot on the top-right corner (scr17 register).
  final bool showActiveDot;

  /// Active presence dot color (defaults to tertiary emerald #15966A).
  final Color activeDotColor;

  const MiniSocialBrandMark({
    super.key,
    this.size = 40.0,
    this.borderRadius,
    this.backgroundColor = AppColors.primaryLight,
    this.letterColor = Colors.white,
    this.showActiveDot = false,
    this.activeDotColor = AppColors.success,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? (size / 40.0 * AppShapes.radiusBrandMark);
    final dotSize = (size * 0.22).clamp(7.0, 16.0);
    final dotBorderWidth = (size * 0.04).clamp(1.5, 3.0);

    return Semantics(
      label: 'Mini Social Brand Mark',
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
                color: backgroundColor,
                borderRadius: BorderRadius.circular(effectiveRadius),
                boxShadow: [
                  BoxShadow(
                    color: backgroundColor.withValues(alpha: 0.20),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                'M',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTypography.fontFamily,
                  fontFamilyFallback: AppTypography.fontFamilyFallback,
                  fontSize: size * 0.55,
                  fontWeight: FontWeight.w800,
                  color: letterColor,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
            ),
            if (showActiveDot)
              Positioned(
                top: -1,
                right: -1,
                child: Container(
                  width: dotSize,
                  height: dotSize,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: activeDotColor,
                    border: Border.all(
                      color: Colors.white,
                      width: dotBorderWidth,
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
