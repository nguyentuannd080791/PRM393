import 'package:flutter/material.dart';
import 'package:clone_facebook/features/profile/domain/entities/user_profile.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfileView profile;

  const ProfileHeader({
    super.key,
    required this.profile,
  });

  String _formatJoinDate(DateTime date) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final monthName = months[date.month - 1];
    return 'Joined $monthName ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final user = profile.user;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cover Photo + Overlapping Avatar Stack
        Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomLeft,
          children: [
            // Cover Image
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.surfaceContainerHighest,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                image: user.coverUrl != null && user.coverUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(user.coverUrl!),
                        fit: BoxFit.cover,
                        onError: (_, _) {},
                      )
                    : null,
              ),
              child: user.coverUrl == null || user.coverUrl!.isEmpty
                  ? Center(
                      child: Icon(
                        Icons.landscape_outlined,
                        size: 48,
                        color: colorScheme.onSurfaceVariant.withAlpha(100),
                      ),
                    )
                  : null,
            ),

            // Circular Avatar overlapping bottom edge
            Positioned(
              bottom: -48,
              left: 16,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: colorScheme.primary,
                  backgroundImage: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? NetworkImage(user.avatarUrl!)
                      : null,
                  onBackgroundImageError: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                      ? (_, _) {}
                      : null,
                  child: user.avatarUrl == null || user.avatarUrl!.isEmpty
                      ? Text(
                          user.fullName.isNotEmpty
                              ? user.fullName.characters.first.toUpperCase()
                              : '?',
                          style: theme.textTheme.headlineMedium?.copyWith(
                            color: colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 56), // Spacing for avatar overlap

        // User Info Section
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display Name
              Text(
                user.fullName,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              // Friends Count
              if (profile.friendsCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '${profile.friendsCount} friends'
                  '${profile.mutualFriendsCount > 0 ? ' • ${profile.mutualFriendsCount} mutual' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],

              // Bio
              if (user.bio != null && user.bio!.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  user.bio!.trim(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Workplace
              if (user.workplace != null && user.workplace!.trim().isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.work_outline, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Works at ${user.workplace}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // City
              if (user.city != null && user.city!.trim().isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lives in ${user.city}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              // Joined Date
              Row(
                children: [
                  Icon(Icons.calendar_today_outlined, size: 18, color: colorScheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text(
                    _formatJoinDate(user.createdAt),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
