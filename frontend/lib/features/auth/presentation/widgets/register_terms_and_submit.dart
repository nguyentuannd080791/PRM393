import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_shapes.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';

class RegisterTermsAndSubmit extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onLogin;

  const RegisterTermsAndSubmit({
    super.key,
    required this.isLoading,
    required this.onSubmit,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Sign Up Button (Primary #0866FF, 48dp)
        SizedBox(
          height: 48,
          child: FilledButton(
            key: const Key('registerSubmitButton'),
            onPressed: isLoading ? null : onSubmit,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primaryAction,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShapes.radiusButton),
              ),
              elevation: 0,
            ),
            child: isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign Up',
                        style: AppTypography.labelLg.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                    ],
                  ),
          ),
        ),
        const SizedBox(height: 20),

        // Destination Link: Already have an account? Log In
        Center(
          child: Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                'Already have an account?',
                style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
              ),
              TextButton(
                key: const Key('registerLoginButton'),
                onPressed: () {
                  onLogin();
                  try {
                    context.pop();
                  } catch (_) {
                    Navigator.of(context).maybePop();
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                ),
                child: Text(
                  'Log In',
                  style: AppTypography.labelMd.copyWith(
                    color: AppColors.primaryAction,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
