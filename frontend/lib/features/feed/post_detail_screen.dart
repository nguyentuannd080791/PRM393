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
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: post.likeCount == 0
                              ? null
                              : () => _showLikes(context, post.id),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.favorite,
                                  size: 18,
                                  color: socialBlue,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '${post.likeCount} ${post.likeCount == 1 ? 'Like' : 'Likes'}',
                                  style: const TextStyle(
                                    color: socialBlue,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(
                          Icons.chat_bubble,
                          size: 18,
                          color: socialMuted,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '${post.commentCount} ${post.commentCount == 1 ? 'Comment' : 'Comments'}',
                          style: const TextStyle(
                            color: socialMuted,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
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
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
            child: Row(
              children: [
                const Text(
                  'Liked by',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 8),
                if (likes.asData != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: socialTint,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${likes.asData!.value.length}',
                      style: const TextStyle(
                        color: socialBlue,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: likes.when(
              loading: () => const LoadingView(),
              error: (error, _) => Center(child: Text(error.toString())),
              data: (users) => users.isEmpty
                  ? const Center(child: Text('No likes yet.'))
                  : ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, i) => ListTile(
                        leading: UserAvatar(users[i].name, radius: 18),
                        title: Text(
                          users[i].name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        onTap: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutePaths.profilePath(users[i].id));
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
