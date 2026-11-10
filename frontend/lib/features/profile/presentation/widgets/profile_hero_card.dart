import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/core/enums/app_enums.dart';
import 'package:clone_facebook/core/models/app_models.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_shapes.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';
import 'package:clone_facebook/core/widgets/text_avatar.dart';
import 'package:clone_facebook/features/profile/domain/entities/user_profile.dart';
import 'package:clone_facebook/features/profile/presentation/widgets/profile_action_button.dart';

class ProfileHeroCard extends StatelessWidget {
  final UserModel user;
  final UserProfileView profileView;
  final AsyncValue<List<FeedPostView>> postsAsync;
  final int additionalPostsCount;
  final String effectiveId;

  const ProfileHeroCard({
    super.key,
    required this.user,
    required this.profileView,
    required this.postsAsync,
    required this.additionalPostsCount,
    required this.effectiveId,
  });

  String _formatJoinDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthName = months[date.month - 1];
    return 'Joined $monthName ${date.year}';
  }

  Widget _buildMetricsRow(int postsCount, int friendsCount, ColorScheme colorScheme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Posts Count Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppShapes.radiusButton),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$postsCount',
                key: const Key('posts_count'),
                style: AppTypography.titleSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'posts',
                style: AppTypography.captionMd.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: colorScheme.onSurfaceVariant,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        // Friends Count Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(AppShapes.radiusButton),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$friendsCount',
                key: const Key('friends_count'),
                style: AppTypography.titleSm.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'friends',
                style: AppTypography.captionMd.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isSelf = profileView.relationshipStatus == UserRelationshipStatus.self;
    final derivedHandle = '@${user.fullName.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
    final joinDateStr = _formatJoinDate(user.createdAt);

    return Material(
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppShapes.radiusCard),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 76px Circular Initials Avatar
            TextAvatar(
              name: user.fullName,
              size: 76.0,
              backgroundColor: colorScheme.primaryContainer,
              textColor: colorScheme.onPrimaryContainer,
              showOnlineIndicator: true,
              onlineIndicatorColor: AppColors.success,
            ),
            const SizedBox(height: 12),

            // Full Name
            Text(
              user.fullName,
              key: const Key('profile_name'),
              style: AppTypography.titleMd.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            // Derived Handle & Join Date
            const SizedBox(height: 2),
            Text(
              '$derivedHandle • $joinDateStr',
              style: AppTypography.captionMd.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            // Bio
            if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  user.bio!.trim(),
                  style: AppTypography.bodyMd.copyWith(
                    color: colorScheme.onSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Compact Metrics Badges (Stats Row)
            postsAsync.when(
              data: (posts) {
                final total = posts is PaginatedPostsResult
                    ? posts.total
                    : (posts.length + additionalPostsCount);
                return _buildMetricsRow(total, profileView.friendsCount, colorScheme);
              },
              loading: () => _buildMetricsRow(0, profileView.friendsCount, colorScheme),
              error: (_, _) => _buildMetricsRow(0, profileView.friendsCount, colorScheme),
            ),

            const SizedBox(height: 16),

            // Action Button: Edit Profile (Self) or Friendship Action (Stranger)
            if (isSelf)
              SizedBox(
                width: double.infinity,
                height: 44,
                child: OutlinedButton.icon(
                  key: const Key('profile_edit_button'),
                  onPressed: () => context.push(AppRoutePaths.profileEdit),
                  icon: Icon(Icons.edit_outlined, size: 18, color: colorScheme.primary),
                  label: Text(
                    'Edit Profile',
                    key: const Key('edit_profile_button'),
                    style: AppTypography.labelMd.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    side: BorderSide(color: colorScheme.outlineVariant),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppShapes.radiusButton),
                    ),
                  ),
                ),
              )
            else
              ProfileActionButton(
                userId: effectiveId,
                status: profileView.relationshipStatus,
              ),
          ],
        ),
      ),
    );
  }
}
