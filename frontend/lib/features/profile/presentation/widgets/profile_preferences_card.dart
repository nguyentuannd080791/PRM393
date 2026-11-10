import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_shapes.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';
import 'package:clone_facebook/core/theme/theme_provider.dart';

class ProfilePreferencesCard extends ConsumerWidget {
  final VoidCallback onLogout;

  const ProfilePreferencesCard({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Preferences / Theme Mode Switcher Card (E2E Test Compatibility)
        Material(
          color: colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusCard),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  'Preferences',
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              SwitchListTile(
                key: const Key('theme_mode_switch'),
                value: isDark,
                onChanged: (val) {
                  ref.read(themeModeProvider.notifier).toggleTheme();
                },
                title: Text(
                  'Dark Mode',
                  style: AppTypography.labelMd.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                subtitle: Text(
                  isDark ? 'Dark theme enabled' : 'Light theme enabled',
                  style: AppTypography.captionSm.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                secondary: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Logout Tile (E2E Test Compatibility)
        Material(
          color: colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusCard),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: ListTile(
            key: const Key('logout_button'),
            onTap: onLogout,
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.errorContainer,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.logout, color: AppColors.destructive, size: 20),
            ),
            title: Text(
              'Log Out',
              style: AppTypography.titleSm.copyWith(
                color: AppColors.destructive,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              'You will be returned to the login screen.',
              style: AppTypography.captionSm.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 16),

        // Warm Minimalist Status Banner (scr13_profile)
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(AppShapes.radiusCard),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_outlined,
                  color: colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text-only sanctuary',
                      style: AppTypography.labelSm.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'No feeds to scroll. Thoughtful conversations only. Help & Support',
                      style: AppTypography.captionSm.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
