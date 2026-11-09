import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/widgets/loading_view.dart';
import 'package:clone_facebook/core/widgets/user_avatar.dart';
import 'package:clone_facebook/features/friends/widgets/friends_ui.dart';

import 'feed_provider.dart';
import 'widgets/post_card.dart';

/// SCR02: one full post, its actions, and the likes list (bottom sheet).
class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final post = ref.watch(postDetailProvider(postId));
    return Member4Scaffold(
      title: 'Post',
      brand: false,
      body: post.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
        data: (post) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SocialCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PostHeader(post),
                  const SizedBox(height: 16),
                  SelectableText(
                    post.content,
                    style: const TextStyle(fontSize: 17, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      InkWell(
                        onTap: post.likeCount == 0
                            ? null
                            : () => _showLikes(context, post.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            '${post.likeCount} ${post.likeCount == 1 ? 'like' : 'likes'}',
                            style: TextStyle(
                              color: post.likeCount == 0
                                  ? socialMuted
                                  : socialBlue,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        '${post.commentCount} ${post.commentCount == 1 ? 'comment' : 'comments'}',
                        style: const TextStyle(color: socialMuted),
                      ),
                    ],
                  ),
                  const Divider(height: 1),
                  PostActionRow(post),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLikes(BuildContext context, String id) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => _LikesSheet(id),
      );
}

class _LikesSheet extends ConsumerWidget {
  const _LikesSheet(this.postId);
  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final likes = ref.watch(postLikesProvider(postId));
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.6,
      child: likes.when(
        loading: () => const LoadingView(),
        error: (error, _) => Center(child: Text(error.toString())),
        data: (users) => users.isEmpty
            ? const Center(child: Text('No likes yet.'))
            : ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, i) => ListTile(
                  leading: UserAvatar(users[i].name),
                  title: Text(users[i].name),
                  onTap: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutePaths.profilePath(users[i].id));
                  },
                ),
              ),
      ),
    );
  }
}
