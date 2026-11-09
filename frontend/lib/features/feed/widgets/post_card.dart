import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/widgets/user_avatar.dart';
import 'package:clone_facebook/features/friends/widgets/friends_ui.dart';

import '../feed_provider.dart';
import '../models/feed_models.dart';

class PostHeader extends StatelessWidget {
  const PostHeader(this.post, {super.key});
  final FeedPost post;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: () => context.push(AppRoutePaths.profilePath(post.author.id)),
    child: Row(
      children: [
        UserAvatar(post.author.name, radius: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.author.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              Text(
                requestTime(post.createdAt),
                style: const TextStyle(color: socialMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Like / Comment / Save for one post, shared by SCR01 and SCR02.
class PostActionRow extends ConsumerWidget {
  const PostActionRow(this.post, {super.key});
  final FeedPost post;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref.watch(postActionsProvider).contains(post.id);
    final commentsPath = ref.watch(commentsPathBuilderProvider);
    final actions = ref.read(postActionsProvider.notifier);

    Future<void> run(Future<void> Function() action) async {
      try {
        await action();
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.toString())));
        }
      }
    }

    Widget button(
      IconData icon,
      String label,
      VoidCallback? onTap, {
      bool active = false,
      String? tooltip,
    }) => Expanded(
      child: Tooltip(
        message: tooltip ?? label,
        child: TextButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 20),
          label: Text(label),
          style: TextButton.styleFrom(
            foregroundColor: active ? socialBlue : socialMuted,
            minimumSize: const Size(0, 44),
          ),
        ),
      ),
    );

    return Row(
      children: [
        button(
          post.likedByMe ? Icons.thumb_up : Icons.thumb_up_outlined,
          post.likedByMe ? 'Liked' : 'Like',
          busy ? null : () => run(() => actions.like(post)),
          active: post.likedByMe,
          tooltip: post.likedByMe ? 'Unlike' : 'Like',
        ),
        button(
          Icons.mode_comment_outlined,
          'Comment',
          commentsPath == null
              ? null
              : () => context.push(commentsPath(post.id)),
          tooltip: 'Comments',
        ),
        button(
          post.savedByMe ? Icons.bookmark : Icons.bookmark_border,
          post.savedByMe ? 'Saved' : 'Save',
          busy ? null : () => run(() => actions.save(post)),
          active: post.savedByMe,
          tooltip: post.savedByMe ? 'Unsave' : 'Save',
        ),
      ],
    );
  }
}

class PostCard extends StatelessWidget {
  const PostCard(this.post, {super.key});
  final FeedPost post;

  @override
  Widget build(BuildContext context) => SocialCard(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        PostHeader(post),
        const SizedBox(height: 12),
        InkWell(
          onTap: () => context.push(AppRoutePaths.postDetailPath(post.id)),
          child: SizedBox(
            width: double.infinity,
            child: Text(
              post.content,
              maxLines: 6,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, height: 1.45),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '${post.likeCount} ${post.likeCount == 1 ? 'Like' : 'Likes'} · '
          '${post.commentCount} ${post.commentCount == 1 ? 'Comment' : 'Comments'}',
          style: const TextStyle(
            color: socialMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        PostActionRow(post),
      ],
    ),
  );
}
