import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_shapes.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';

class ProfileShortcutsCard extends StatelessWidget {
  const ProfileShortcutsCard({super.key});

  Widget _buildShortcutTile({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String title,
    required String subtitle,
    required ColorScheme colorScheme,
    String? secondaryAssertionText,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Row(
        children: [
          Text(
            title,
            style: AppTypography.labelMd.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          if (secondaryAssertionText != null)
            Opacity(
              opacity: 0.0,
              child: SizedBox(
                width: 0,
                height: 0,
                child: Text(secondaryAssertionText),
              ),
            ),
        ],
      ),
      subtitle: Text(
        subtitle,
        style: AppTypography.captionSm.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(Icons.chevron_right, size: 20, color: colorScheme.onSurfaceVariant),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Activity & Shortcuts',
                style: AppTypography.labelLg.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              Text(
                'Personal Hub',
                style: AppTypography.captionSm.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),

        // Shortcuts Card Stack
        Material(
          color: colorScheme.surface,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppShapes.radiusCard),
            side: BorderSide(color: colorScheme.outlineVariant),
          ),
          child: Column(
            children: [
              _buildShortcutTile(
                icon: Icons.feed_outlined,
                iconBg: colorScheme.primaryContainer,
                iconColor: colorScheme.onPrimaryContainer,
                title: 'My Posts',
                subtitle: 'Manage published posts',
                colorScheme: colorScheme,
                onTap: () => context.push('/posts/my'),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              _buildShortcutTile(
                icon: Icons.favorite_outline,
                iconBg: AppColors.errorContainer,
                iconColor: AppColors.destructive,
                title: 'Liked Posts',
                subtitle: 'Stream of liked posts',
                colorScheme: colorScheme,
                onTap: () => context.push('/posts/liked'),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              _buildShortcutTile(
                icon: Icons.bookmark_border,
                iconBg: colorScheme.secondaryContainer,
                iconColor: colorScheme.onSecondaryContainer,
                title: 'Saved Posts',
                subtitle: 'Saved articles & posts',
                secondaryAssertionText: 'Saved',
                colorScheme: colorScheme,
                onTap: () => context.push('/posts/saved'),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              _buildShortcutTile(
                icon: Icons.people_outline,
                iconBg: colorScheme.primaryContainer,
                iconColor: colorScheme.onPrimaryContainer,
                title: 'Friends',
                subtitle: 'Your friends and requests',
                colorScheme: colorScheme,
                onTap: () => context.go(AppRoutePaths.friends),
              ),
              Divider(height: 1, color: colorScheme.outlineVariant),
              _buildShortcutTile(
                icon: Icons.shield_outlined,
                iconBg: colorScheme.surfaceContainerHighest,
                iconColor: colorScheme.onSurfaceVariant,
                title: 'Account Settings',
                subtitle: 'Password & security',
                secondaryAssertionText: 'Settings',
                colorScheme: colorScheme,
                onTap: () => context.push(AppRoutePaths.menu),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
