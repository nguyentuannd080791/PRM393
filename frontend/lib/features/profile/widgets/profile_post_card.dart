import 'package:flutter/material.dart';
import 'package:clone_facebook/core/enums/app_enums.dart';
import 'package:clone_facebook/core/models/app_models.dart';
import 'package:clone_facebook/core/utils/formatters.dart';

class ProfilePostCard extends StatelessWidget {
  final FeedPostView postView;

  const ProfilePostCard({
    super.key,
    required this.postView,
  });

  IconData _audienceIcon(PostAudience audience) {
    switch (audience) {
      case PostAudience.public:
        return Icons.public;
      case PostAudience.friends:
        return Icons.people;
      case PostAudience.onlyMe:
        return Icons.lock;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final post = postView.post;
    final author = postView.author;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Author row
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: colorScheme.primaryContainer,
                  backgroundImage: author.avatarUrl != null && author.avatarUrl!.isNotEmpty
                      ? NetworkImage(author.avatarUrl!)
                      : null,
                  onBackgroundImageError: author.avatarUrl != null && author.avatarUrl!.isNotEmpty
                      ? (_, _) {}
                      : null,
                  child: author.avatarUrl == null || author.avatarUrl!.isEmpty
                      ? Text(
                          author.fullName.isNotEmpty
                              ? author.fullName.characters.first.toUpperCase()
                              : '?',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        author.fullName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            AppFormatters.formatRelativeTime(post.createdAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '\u2022',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            _audienceIcon(post.audience),
                            size: 14,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Content text
            if (post.content != null && post.content!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                post.content!.trim(),
                style: theme.textTheme.bodyMedium,
              ),
            ],

            // Media Preview
            if (post.mediaUrls.isNotEmpty) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    post.mediaUrls.first,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, stack) => Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.image, size: 40, color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 10),
            const Divider(height: 1),
            const SizedBox(height: 8),

            // Stats row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.thumb_up_alt_outlined, size: 16, color: colorScheme.primary),
                    const SizedBox(width: 4),
                    Text(
                      AppFormatters.formatCompactNumber(postView.reactionCount),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${AppFormatters.formatCompactNumber(postView.commentCount)} comments',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
