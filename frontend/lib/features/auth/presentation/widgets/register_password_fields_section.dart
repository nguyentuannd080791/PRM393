import 'package:flutter/material.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_shapes.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';

class RegisterPasswordFieldsSection extends StatefulWidget {
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const RegisterPasswordFieldsSection({
    super.key,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<RegisterPasswordFieldsSection> createState() =>
      _RegisterPasswordFieldsSectionState();
}

class _RegisterPasswordFieldsSectionState
    extends State<RegisterPasswordFieldsSection> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Password Field (BR-02: >=8 chars, >=1 letter & >=1 digit)
        TextFormField(
          key: const Key('registerPasswordField'),
          controller: widget.passwordController,
          obscureText: !_isPasswordVisible,
          style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Password',
            labelStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
            hintText: 'Create password',
            hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
            prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurfaceVariant, size: 20),
            helperText: 'Must be at least 8 characters with letters & numbers',
            helperStyle: AppTypography.captionSm.copyWith(color: colorScheme.onSurfaceVariant),
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
              return 'Please enter a password';
            }
            if (value.length < 8) {
              return 'Password must be at least 8 characters';
            }
            final hasLetter = RegExp(r'[A-Za-z]').hasMatch(value);
            final hasDigit = RegExp(r'\d').hasMatch(value);
            if (!hasLetter || !hasDigit) {
              return 'Password must contain at least one letter and one number';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Confirm Password Field
        TextFormField(
          key: const Key('registerConfirmPasswordField'),
          controller: widget.confirmPasswordController,
          obscureText: !_isConfirmPasswordVisible,
          style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            labelStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
            hintText: 'Repeat password',
            hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
            prefixIcon: Icon(Icons.lock_reset_outlined, color: colorScheme.onSurfaceVariant, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
              onPressed: () {
                setState(() {
                  _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
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
            if (value != null && value.isNotEmpty && value != widget.passwordController.text) {
              return 'Passwords do not match';
            }
            return null;
          },
        ),
      ],
    );
  }
}
