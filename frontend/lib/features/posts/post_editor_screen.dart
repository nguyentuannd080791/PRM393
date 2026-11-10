import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/loading_view.dart';
import '../auth/providers/auth_provider.dart';
import '../feed/feed_provider.dart';
import 'posts_repository.dart';

/// SCR04: create mode by default; edit mode when [postId] is given.
class CreatePostPage extends ConsumerStatefulWidget {
  const CreatePostPage({
    super.key,
    this.postId,
    this.initialContent = '',
    this.initialAudience = 'public',
  });

  final String? postId;
  final String initialContent;
  final String initialAudience;

  @override
  ConsumerState<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends ConsumerState<CreatePostPage> {
  static const _blue = Color(0xFF0759CC);
  static const _maxPostLength = 5000;
  late final _controller = TextEditingController(text: widget.initialContent);
  late String _audience = widget.initialAudience;
  bool _publishing = false;

  bool get _editing => widget.postId != null;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final content = _controller.text.trim();
    if (content.isEmpty || _publishing) return;
    setState(() => _publishing = true);
    try {
      final repo = ref.read(postsRepositoryProvider);
      if (_editing) {
        await repo.updatePost(widget.postId!, content, audience: _audience);
        ref.invalidate(postDetailProvider(widget.postId!));
      } else {
        await repo.createPost(content, audience: _audience);
      }
      ref.invalidate(feedProvider);
      if (mounted) context.pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).user;
    final name = user?.fullName ?? 'User';
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    final characterCount = _controller.text.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF6F8FC),
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(
          _editing ? 'Edit Post' : 'Create Post',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            tooltip: 'Profile',
            icon: const CircleAvatar(
              radius: 15,
              backgroundColor: Color(0xFF1769E0),
              child: Icon(Icons.person, color: Colors.white, size: 19),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            Container(
              constraints: const BoxConstraints(minHeight: 360),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x10000000),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: const Color(0xFFE5EEFF),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: _blue,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEAF1FF),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    _audienceLabel(_audience),
                                    style: const TextStyle(
                                      color: _blue,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Text(
                              'Posting to your profile stream',
                              style: TextStyle(
                                color: Color(0xFF687684),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Post audience',
                        initialValue: _audience,
                        onSelected: (value) =>
                            setState(() => _audience = value),
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'public',
                            child: ListTile(
                              leading: Icon(Icons.public),
                              title: Text('Anyone'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'friends',
                            child: ListTile(
                              leading: Icon(Icons.people_outline),
                              title: Text('Friends'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          PopupMenuItem(
                            value: 'only_me',
                            child: ListTile(
                              leading: Icon(Icons.lock_outline),
                              title: Text('Only me'),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F4FA),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.public,
                                size: 14,
                                color: Color(0xFF687684),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _audienceMenuLabel(_audience),
                                style: const TextStyle(
                                  color: Color(0xFF526071),
                                  fontSize: 12,
                                ),
                              ),
                              const Icon(Icons.arrow_drop_down, size: 17),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _controller,
                    maxLength: _maxPostLength,
                    maxLines: null,
                    minLines: 10,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'What would you like to share?',
                      counterText: '',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.55),
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Text(
                        '$characterCount / $_maxPostLength',
                        style: const TextStyle(
                          color: Color(0xFF687684),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        Icons.circle,
                        size: 8,
                        color: Color(0xFFD7E1F4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                onPressed: _controller.text.trim().isEmpty || _publishing
                    ? null
                    : _publish,
                icon: _publishing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.send_outlined, size: 19),
                label: Text(
                  _publishing
                      ? 'Saving…'
                      : _editing
                      ? 'Save Changes'
                      : 'Publish Post',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _blue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _audienceLabel(String audience) => switch (audience) {
    'friends' => 'Friends',
    'only_me' => 'Only me',
    _ => 'Public',
  };

  static String _audienceMenuLabel(String audience) => switch (audience) {
    'friends' => 'Friends',
    'only_me' => 'Only me',
    _ => 'Anyone',
  };
}

/// Loads the post, then opens SCR04 in edit mode. The API rejects non-authors.
class EditPostPage extends ConsumerWidget {
  const EditPostPage({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) =>
      ref.watch(postDetailProvider(postId)).when(
        loading: () => const Scaffold(body: LoadingView()),
        error: (error, _) => Scaffold(
          appBar: AppBar(title: const Text('Edit Post')),
          body: Center(child: Text(error.toString())),
        ),
        data: (post) => CreatePostPage(
          postId: post.id,
          initialContent: post.content,
          initialAudience: post.audience,
        ),
      );
}
