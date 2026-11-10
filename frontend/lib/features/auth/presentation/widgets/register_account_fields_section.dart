import 'package:flutter/material.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_shapes.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';

class RegisterAccountFieldsSection extends StatelessWidget {
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;

  const RegisterAccountFieldsSection({
    super.key,
    required this.fullNameController,
    required this.emailController,
    required this.phoneController,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Full Name Field (1-50 chars, BR-01)
        TextFormField(
          key: const Key('registerFullNameField'),
          controller: fullNameController,
          style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Full Name',
            labelStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
            hintText: 'e.g. An Nguyen',
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
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            if (value.trim().length > 50) {
              return 'Full name cannot exceed 50 characters';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Email Field (BR-01)
        TextFormField(
          key: const Key('registerEmailField'),
          controller: emailController,
          keyboardType: TextInputType.emailAddress,
          style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Email Address',
            labelStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
            hintText: 'name@example.com',
            hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
            prefixIcon: Icon(Icons.email_outlined, color: colorScheme.onSurfaceVariant, size: 20),
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
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your email';
            }
            final isEmail = RegExp(
              r'^[a-zA-Z0-9_.+-]+@[a-zA-Z0-9-]+\.[a-zA-Z0-9-.]+$',
            ).hasMatch(value.trim());
            if (!isEmail) {
              return 'Enter a valid email address';
            }
            return null;
          },
        ),
        const SizedBox(height: 14),

        // Phone Field (Optional, 9-11 digits)
        TextFormField(
          key: const Key('registerPhoneField'),
          controller: phoneController,
          keyboardType: TextInputType.phone,
          style: AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
          decoration: InputDecoration(
            labelText: 'Phone Number (Optional)',
            labelStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
            hintText: '+84 912 345 678',
            hintStyle: AppTypography.bodyMd.copyWith(color: AppColors.slate400),
            prefixIcon: Icon(Icons.phone_outlined, color: colorScheme.onSurfaceVariant, size: 20),
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
            if (value != null && value.trim().isNotEmpty) {
              final isPhone = RegExp(r'^[0-9]{9,11}$').hasMatch(value.trim());
              if (!isPhone) {
                return 'Phone must be between 9 and 11 digits';
              }
            }
            return null;
          },
        ),
      ],
    );
  }
}
