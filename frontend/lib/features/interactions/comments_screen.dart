import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/widgets/loading_view.dart';
import 'package:clone_facebook/core/widgets/user_avatar.dart';
import 'package:clone_facebook/features/friends/widgets/friends_ui.dart';

import 'interactions_provider.dart';

/// SCR07: read, add and delete own comments on one post.
class CommentsScreen extends ConsumerStatefulWidget {
  const CommentsScreen({super.key, required this.postId});
  final String postId;

  @override
  ConsumerState<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends ConsumerState<CommentsScreen> {
  final _controller = TextEditingController();
  bool _sending = false;
  String? _inputError;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toast(String message) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      // Inline, so the message never covers the Send button like a snackbar would.
      setState(() => _inputError = 'Please enter the required information.');
      return;
    }
    if (_sending) return;
    setState(() => _sending = true);
    try {
      await addComment(ref, widget.postId, text);
      _controller.clear();
    } catch (error) {
      if (mounted) _toast(error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _delete(PostComment comment) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await deleteComment(ref, widget.postId, comment.id);
    } catch (error) {
      if (mounted) _toast(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final comments = ref.watch(commentsProvider(widget.postId));
    return Member4Scaffold(
      title: 'Comments',
      brand: false,
      body: Column(
        children: [
          Expanded(
            child: comments.when(
              loading: () => const LoadingView(),
              error: (error, _) => SocialMessage(
                error.toString(),
                icon: Icons.cloud_off_outlined,
                onRetry: () => ref.invalidate(commentsProvider(widget.postId)),
              ),
              data: (items) => items.isEmpty
                  ? const SocialMessage(
                      'No comments yet. Be the first to comment.',
                      icon: Icons.chat_bubble_outline,
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.refresh(commentsProvider(widget.postId).future),
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, i) =>
                            _CommentTile(items[i], onDelete: _delete),
                      ),
                    ),
            ),
          ),
          const Divider(height: 1),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      onChanged: (_) {
                        if (_inputError != null) {
                          setState(() => _inputError = null);
                        }
                      },
                      decoration: InputDecoration(
                        hintText: 'Write a comment…',
                        counterText: '',
                        errorText: _inputError,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Send',
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const ActionSpinner()
                        : const Icon(Icons.send, color: socialBlue),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile(this.comment, {required this.onDelete});
  final PostComment comment;
  final ValueChanged<PostComment> onDelete;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      InkWell(
        onTap: () => context.push(AppRoutePaths.profilePath(comment.author.id)),
        child: UserAvatar(comment.author.name, radius: 18),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 10),
          decoration: BoxDecoration(
            color: socialTint,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      comment.author.name,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    requestTime(comment.createdAt),
                    style: const TextStyle(color: socialMuted, fontSize: 12),
                  ),
                  if (comment.isMine)
                    IconButton(
                      tooltip: 'Delete comment',
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: () => onDelete(comment),
                    )
                  else
                    const SizedBox(width: 8),
                ],
              ),
              Text(comment.content, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ),
    ],
  );
}
