import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/models/app_models.dart';
import 'package:clone_facebook/core/theme/app_colors.dart';
import 'package:clone_facebook/core/theme/app_typography.dart';
import 'package:clone_facebook/features/profile/widgets/profile_post_card.dart';

class ProfilePostsSection extends StatelessWidget {
  final AsyncValue<List<FeedPostView>> postsAsync;
  final List<FeedPostView> additionalPosts;
  final bool isLoadingMore;

  const ProfilePostsSection({
    super.key,
    required this.postsAsync,
    required this.additionalPosts,
    required this.isLoadingMore,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Text(
            'Posts',
            style: AppTypography.titleSm.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
        ),

        // Posts Stream
        postsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Failed to load posts.',
                style: AppTypography.bodyMd.copyWith(color: AppColors.error),
              ),
            ),
          ),
          data: (posts) {
            final combinedPosts = [...posts, ...additionalPosts];
            if (combinedPosts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.article_outlined,
                        size: 44,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No posts yet',
                        style: AppTypography.bodyMd.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: combinedPosts.length,
                  itemBuilder: (ctx, index) {
                    return ProfilePostCard(postView: combinedPosts[index]);
                  },
                ),
                if (isLoadingMore)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}
