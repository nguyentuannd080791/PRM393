import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';

import 'feed_repository.dart';
import 'models/feed_models.dart';

/// Member 3 can supply the Comments route here without Member 1 depending on it.
final commentsPathBuilderProvider = Provider<String Function(String)?>(
  (ref) => null,
);

class FeedState {
  const FeedState({
    this.posts = const [],
    this.hasMore = false,
    this.page = 1,
    this.loadingMore = false,
  });
  final List<FeedPost> posts;
  final bool hasMore;
  final int page;
  final bool loadingMore;

  FeedState copyWith({
    List<FeedPost>? posts,
    bool? hasMore,
    int? page,
    bool? loadingMore,
  }) => FeedState(
    posts: posts ?? this.posts,
    hasMore: hasMore ?? this.hasMore,
    page: page ?? this.page,
    loadingMore: loadingMore ?? this.loadingMore,
  );
}

class FeedController extends AsyncNotifier<FeedState> {
  @override
  Future<FeedState> build() async {
    // Start over when a different account signs in.
    if (ref.watch(sessionUserIdProvider) == null) return const FeedState();
    final page = await ref.watch(feedRepositoryProvider).feed(1);
    return FeedState(posts: page.posts, hasMore: page.hasMore);
  }

  Future<void> refresh() async {
    ref.invalidateSelf();
    await future;
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.loadingMore || !current.hasMore) return;
    state = AsyncData(current.copyWith(loadingMore: true));
    try {
      final next = current.page + 1;
      final page = await ref.read(feedRepositoryProvider).feed(next);
      if (!ref.mounted) return;
      final known = {for (final p in current.posts) p.id};
      state = AsyncData(
        FeedState(
          posts: [
            ...current.posts,
            ...page.posts.where((p) => !known.contains(p.id)),
          ],
          hasMore: page.hasMore,
          page: next,
        ),
      );
    } catch (_) {
      // Keep the posts already shown; the user can scroll again to retry.
      if (ref.mounted) state = AsyncData(current);
    }
  }

  void replace(FeedPost post) {
    final current = state.value;
    if (current == null) return;
    state = AsyncData(
      current.copyWith(
        posts: [for (final p in current.posts) p.id == post.id ? post : p],
      ),
    );
  }
}

final feedProvider = AsyncNotifierProvider<FeedController, FeedState>(
  FeedController.new,
);

final postDetailProvider = FutureProvider.autoDispose.family<FeedPost, String>((
  ref,
  id,
) {
  ref.watch(sessionUserIdProvider);
  return ref.watch(feedRepositoryProvider).getPost(id);
});

final postLikesProvider = FutureProvider.autoDispose
    .family<List<FeedUser>, String>(
      (ref, id) => ref.watch(feedRepositoryProvider).likes(id),
    );

/// Like/Save from the feed or detail. Locks per post so a double tap sends one request.
class PostActions extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(sessionUserIdProvider);
    return {};
  }

  Future<void> like(FeedPost post) =>
      _run(post, (repo) => repo.setLike(post.id, !post.likedByMe));

  Future<void> save(FeedPost post) =>
      _run(post, (repo) => repo.setSaved(post.id, !post.savedByMe));

  Future<void> _run(
    FeedPost post,
    Future<FeedPost> Function(FeedRepository) action,
  ) async {
    if (state.contains(post.id)) return;
    state = {...state, post.id};
    try {
      final updated = await action(ref.read(feedRepositoryProvider));
      if (!ref.mounted) return;
      ref.read(feedProvider.notifier).replace(updated);
      ref.invalidate(postDetailProvider(post.id));
      ref.invalidate(postLikesProvider(post.id));
    } finally {
      if (ref.mounted) state = {...state}..remove(post.id);
    }
  }
}

final postActionsProvider = NotifierProvider<PostActions, Set<String>>(
  PostActions.new,
);

/// Notifications refresh every 15 s while a screen watches them (no sockets needed).
final notificationsProvider = FutureProvider.autoDispose<NotificationList>((
  ref,
) {
  if (ref.watch(sessionUserIdProvider) == null) {
    return const NotificationList(items: [], unread: 0);
  }
  final timer = Timer(const Duration(seconds: 15), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(feedRepositoryProvider).notifications();
});

Future<void> markNotificationRead(WidgetRef ref, String id) async {
  await ref.read(feedRepositoryProvider).markRead(id);
  ref.invalidate(notificationsProvider);
}

Future<void> markAllNotificationsRead(WidgetRef ref) async {
  await ref.read(feedRepositoryProvider).markAllRead();
  ref.invalidate(notificationsProvider);
}
