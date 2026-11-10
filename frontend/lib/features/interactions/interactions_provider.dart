import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/features/auth/providers/auth_provider.dart';
import 'package:clone_facebook/features/feed/feed_provider.dart';
import 'package:clone_facebook/features/feed/feed_repository.dart';
import 'package:clone_facebook/features/feed/models/feed_models.dart';

import 'interactions_repository.dart';

export 'interactions_repository.dart';

final commentsProvider = FutureProvider.autoDispose
    .family<List<PostComment>, String>((ref, postId) {
      ref.watch(sessionUserIdProvider);
      return ref.watch(interactionsRepositoryProvider).comments(postId);
    });

// Watching postActionsProvider refetches after every Like/Save toggle,
// so an unliked/unsaved post leaves the list.
final likedPostsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) {
  ref.watch(sessionUserIdProvider);
  ref.watch(postActionsProvider);
  return ref.watch(interactionsRepositoryProvider).likedPosts();
});

final savedPostsProvider = FutureProvider.autoDispose<List<FeedPost>>((ref) {
  ref.watch(sessionUserIdProvider);
  ref.watch(postActionsProvider);
  return ref.watch(interactionsRepositoryProvider).savedPosts();
});

/// Refreshes comments and the post's comment count in Feed and Post Detail.
Future<void> _syncPost(WidgetRef ref, String postId) async {
  ref.invalidate(commentsProvider(postId));
  ref.invalidate(postDetailProvider(postId));
  try {
    final post = await ref.read(feedRepositoryProvider).getPost(postId);
    ref.read(feedProvider.notifier).replace(post);
  } catch (_) {
    // Feed count refreshes on next pull-to-refresh.
  }
}

Future<void> addComment(WidgetRef ref, String postId, String content) async {
  await ref.read(interactionsRepositoryProvider).addComment(postId, content);
  await _syncPost(ref, postId);
}

Future<void> deleteComment(
  WidgetRef ref,
  String postId,
  String commentId,
) async {
  await ref.read(interactionsRepositoryProvider).deleteComment(commentId);
  await _syncPost(ref, postId);
}
