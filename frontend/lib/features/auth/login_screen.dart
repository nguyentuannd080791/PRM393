import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_shapes.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';
import 'package:clone_facebook/core/widgets/brand_mark.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';

/// Screen 16: Login Screen (scr16_login)
/// Blank canvas styling (#F8F9FF), MiniSocialBrandMark at top,
/// "Mini Social", text inputs with #EFF3FF fill, 10dp radius, #E4EAF2 border,
/// primary #0866FF 48dp action button, link for Register.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(authStateProvider.notifier).clearError();
      }
    });
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final authNotifier = ref.read(authStateProvider.notifier);
    final success = await authNotifier.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    if (mounted) {
      if (success) {
        try {
          context.go(AppRoutePaths.feed);
        } catch (_) {
          // Fallback if mounted outside GoRouter in widget tests
        }
      } else {
        _passwordController.clear();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [

                    // Top Brand Identity Block (scr16_login)
                    Center(
                      child: Column(
                        children: [
                          const MiniSocialBrandMark(
                            size: 64,
                            borderRadius: 16,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Mini Social',
                            style: AppTypography.headlineLg.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Stay close to the people who matter.',
                            style: AppTypography.bodyMd.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Main Form Card (SurfaceContainerLowest #FFFFFF, 14dp radius)
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(AppShapes.radiusCard),
                        border: Border.all(color: colorScheme.outlineVariant),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Lockout Banner (BR-04, MSG-02/MSG-05)
                          if (authState.isLockedOut) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(AppShapes.radiusButton),
                                border: Border.all(color: AppColors.error),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.lock_clock, color: AppColors.error),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Too many attempts. Try again in 5 minutes.',
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.error,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ] else if (authState.errorMessage != null) ...[
                            // Error Message Banner (MSG-04)
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.errorContainer,
                                borderRadius: BorderRadius.circular(AppShapes.radiusButton),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: AppColors.error),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      authState.errorMessage!,
                                      style: AppTypography.bodyMd.copyWith(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Email or Phone Field (BR-01)
                          TextFormField(
                            key: const Key('loginEmailField'),
maxLength: 16,
inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9+]'))],
                            controller: _identifierController,
                            enabled: !authState.isLoading && !authState.isLockedOut,
                            keyboardType: TextInputType.phone,
                            style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
counterText: '',
                              labelText: 'Phone Number',
                              labelStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
                              hintText: '0912345678',
                              hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
                              prefixIcon: Icon(Icons.person_outline, color: colorScheme.onSurfaceVariant, size: 20),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerLow,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: const BorderSide(color: AppColors.primaryAction, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              final phone = (value ?? '').trim();
                              if (phone.isEmpty) {
                                return 'Please enter the required information.';
                              }
                              if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)) {
                                return 'Enter a valid phone number (9-15 digits).';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // Password Field (BR-02)
                          TextFormField(
                            key: const Key('loginPasswordField'),
maxLength: 128,
                            controller: _passwordController,
                            enabled: !authState.isLoading && !authState.isLockedOut,
                            obscureText: !_isPasswordVisible,
                            style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
                            decoration: InputDecoration(
counterText: '',
                              labelText: 'Password',
                              labelStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
                              hintText: '••••••••',
                              hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
                              prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant, size: 20),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _isPasswordVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: colorScheme.onSurfaceVariant,
                                  size: 20,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _isPasswordVisible = !_isPasswordVisible;
                                  });
                                },
                              ),
                              filled: true,
                              fillColor: colorScheme.surfaceContainerLow,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: BorderSide(color: colorScheme.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(AppShapes.radiusInput),
                                borderSide: const BorderSide(color: AppColors.primaryAction, width: 1.5),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Log In Button (Primary #0866FF, 48dp)
                          SizedBox(
                            height: 48,
                            child: FilledButton(
                              key: const Key('loginSubmitButton'),
                              onPressed: (authState.isLoading || authState.isLockedOut)
                                  ? null
                                  : _handleLogin,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.primaryAction,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppShapes.radiusButton),
                                ),
                                elevation: 0,
                              ),
                              child: authState.isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      'Log In',
                                      style: AppTypography.labelLg.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Registration Link Footer
                    Center(
                      child: Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
                          ),
                          TextButton(
                            key: const Key('loginRegisterButton'),
                            onPressed: authState.isLoading
                                ? null
                                : () {
                                    ref.read(authStateProvider.notifier).clearError();
                                    context.push(AppRoutePaths.register);
                                  },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                            child: Text(
                              'Create Account',
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
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

typedef LoginPage = LoginScreen;
