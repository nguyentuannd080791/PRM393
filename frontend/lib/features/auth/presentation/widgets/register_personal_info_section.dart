import 'package:flutter/material.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_shapes.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';

class RegisterPersonalInfoSection extends StatelessWidget {
  final DateTime? selectedBirthday;
  final String? birthdayError;
  final VoidCallback onPickBirthday;
  final String selectedGender;
  final ValueChanged<String> onGenderChanged;

  const RegisterPersonalInfoSection({
    super.key,
    required this.selectedBirthday,
    required this.birthdayError,
    required this.onPickBirthday,
    required this.selectedGender,
    required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Birthday Field (BR-03)
        InkWell(
          key: const Key('registerBirthdayField'),
          onTap: onPickBirthday,
          borderRadius: BorderRadius.circular(AppShapes.radiusInput),
          child: InputDecorator(
            decoration: InputDecoration(
              labelText: 'Birthday',
              labelStyle: AppTypography.bodyMd.copyWith(color: colorScheme.onSurfaceVariant),
              prefixIcon: Icon(Icons.calendar_today_outlined, color: colorScheme.onSurfaceVariant, size: 20),
              errorText: birthdayError,
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
            ),
            child: Text(
              selectedBirthday == null
                  ? 'Select your date of birth'
                  : '${selectedBirthday!.year}-${selectedBirthday!.month.toString().padLeft(2, '0')}-${selectedBirthday!.day.toString().padLeft(2, '0')}',
              style: selectedBirthday == null
                  ? AppTypography.bodyMd.copyWith(color: AppColors.slate400)
                  : AppTypography.bodyMd.copyWith(color: colorScheme.onSurface),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Gender Selection
        Text(
          'Gender',
          style: AppTypography.labelMd.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(value: 'Female', label: Text('Female')),
            ButtonSegment(value: 'Male', label: Text('Male')),
            ButtonSegment(value: 'Custom', label: Text('Custom')),
          ],
          selected: {selectedGender},
          onSelectionChanged: (newSelection) {
            onGenderChanged(newSelection.first);
          },
          style: ButtonStyle(
            shape: WidgetStatePropertyAll(
              RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppShapes.radiusButton),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
