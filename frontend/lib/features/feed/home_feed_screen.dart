import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/widgets/loading_view.dart';
import 'package:clone_facebook/core/widgets/user_avatar.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';
import 'package:clone_facebook/features/friends/widgets/friends_ui.dart';

import 'feed_provider.dart';
import 'widgets/post_card.dart';

/// SCR01: recent posts visible to the signed-in user.
class HomeFeedScreen extends ConsumerStatefulWidget {
  const HomeFeedScreen({super.key});
  @override
  ConsumerState<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends ConsumerState<HomeFeedScreen> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 400) {
        ref.read(feedProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(feedProvider);
    return Member4Scaffold(
      title: 'Mini Social',
      body: feed.when(
        loading: () => const LoadingView(),
        error: (error, _) => _Message(
          text: error.toString(),
          action: 'Retry',
          onAction: () => ref.invalidate(feedProvider),
        ),
        data: (state) => RefreshIndicator(
          onRefresh: () => ref.read(feedProvider.notifier).refresh(),
          child: ListView.separated(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            itemCount: state.posts.length + 2,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              if (index == 0) return const _Composer();
              if (index == state.posts.length + 1) {
                if (state.loadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(12),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return state.posts.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(
                          child: Text(
                            'No posts yet. Add friends or write your first post.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: socialMuted),
                          ),
                        ),
                      )
                    : const SizedBox.shrink();
              }
              return PostCard(state.posts[index - 1]);
            },
          ),
        ),
      ),
    );
  }
}

class _Composer extends ConsumerWidget {
  const _Composer();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(currentUserProvider)?.fullName ?? '';
    return SocialCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          UserAvatar(name, radius: 19),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => context.push(AppRoutePaths.createPost),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F7),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text(
                        "What's on your mind?",
                        style: TextStyle(color: socialMuted),
                      ),
                    ),
                    Icon(Icons.edit_note, size: 20, color: socialMuted),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.text, required this.action, this.onAction});
  final String text;
  final String action;
  final VoidCallback? onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          FilledButton(onPressed: onAction, child: Text(action)),
        ],
      ),
    ),
  );
}
