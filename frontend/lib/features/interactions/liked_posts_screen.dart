import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/widgets/loading_view.dart';
import 'package:clone_facebook/features/feed/models/feed_models.dart';
import 'package:clone_facebook/features/feed/widgets/post_card.dart';
import 'package:clone_facebook/features/friends/widgets/friends_ui.dart';

import 'interactions_provider.dart';

/// SCR08: posts the user liked. Unlike / open post come from the shared PostCard.
class LikedPostsScreen extends StatelessWidget {
  const LikedPostsScreen({super.key});

  @override
  Widget build(BuildContext context) => PostListScreen(
    title: 'Liked Posts',
    provider: likedPostsProvider,
    emptyMessage: 'You have not liked any posts yet.',
    emptyIcon: Icons.favorite_outline,
  );
}

/// Shared by SCR08 and SCR09.
class PostListScreen extends ConsumerWidget {
  const PostListScreen({
    super.key,
    required this.title,
    required this.provider,
    required this.emptyMessage,
    required this.emptyIcon,
  });
  final String title;
  final FutureProvider<List<FeedPost>> provider;
  final String emptyMessage;
  final IconData emptyIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Member4Scaffold(
    title: title,
    brand: false,
    body: ref
        .watch(provider)
        .when(
          // Keep the list visible while it refetches after a toggle.
          skipLoadingOnRefresh: true,
          skipLoadingOnReload: true,
          loading: () => const LoadingView(),
          error: (error, _) => SocialMessage(
            error.toString(),
            icon: Icons.cloud_off_outlined,
            onRetry: () => ref.invalidate(provider),
          ),
          data: (posts) => RefreshIndicator(
            onRefresh: () => ref.refresh(provider.future),
            child: posts.isEmpty
                ? ListView(children: [SocialMessage(emptyMessage, icon: emptyIcon)])
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: posts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, i) => PostCard(posts[i]),
                  ),
          ),
        ),
  );
}
