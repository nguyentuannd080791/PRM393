import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/route_names.dart';
import '../../core/widgets/loading_view.dart';
import '../auth/auth_provider.dart';
import '../feed/feed_provider.dart';
import 'posts_repository.dart';

class MyPostsScreen extends ConsumerStatefulWidget {
  const MyPostsScreen({
    super.key,
    required this.userId,
    this.displayName = 'User',
  });

  final String userId;
  final String displayName;

  @override
  ConsumerState<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends ConsumerState<MyPostsScreen> {
  List<ManagedPost> _posts = const [];
  Object? _loadError;
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedAudience = 'public';
  final Set<String> _busyPosts = {};
  bool _creating = false;

  String? get _currentUserId => ref.read(authStateProvider).user?.id;

  String? get _requestedUserId =>
      widget.userId == 'me' ? _currentUserId : widget.userId;

  bool get _isOwner =>
      _requestedUserId != null && _requestedUserId == _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant MyPostsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) _loadPosts();
  }

  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final userId = _requestedUserId;
      if (userId == null) throw StateError('Please sign in to view posts.');
      final posts = await ref
          .read(postsRepositoryProvider)
          .getUserPosts(userId);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loadError = error;
        _loading = false;
      });
    }
  }

  Future<void> _createPost() async {
    setState(() => _creating = true);
    try {
      final published = await context.push<bool>(AppRoutePaths.createPost);
      if (published != true || !mounted) return;
      await _loadPosts();
      if (mounted) _showMessage('Post published.');
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _editPost(ManagedPost post) async {
    final saved = await context.push<bool>(
      AppRoutePaths.editPostPath(post.id),
    );
    if (saved != true || !mounted) return;
    await _loadPosts();
    if (mounted) _showMessage('Changes saved successfully.');
  }

  Future<void> _deletePost(ManagedPost post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete post?'),
        content: const Text(
          'This post will be removed from your active posts.',
        ),
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
    if (confirmed != true || !mounted) return;
    setState(() => _busyPosts.add(post.id));
    try {
      await ref.read(postsRepositoryProvider).deletePost(post.id);
      ref.invalidate(feedProvider);
      await _loadPosts();
      if (mounted) _showMessage('Post deleted.');
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busyPosts.remove(post.id));
    }
  }

  Future<void> _showInsights(ManagedPost post) async {
    setState(() => _busyPosts.add(post.id));
    try {
      await context.pushNamed<void>(
        AppRouteNames.postInsights,
        pathParameters: {'id': post.id},
      );
    } catch (error) {
      if (mounted) _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _busyPosts.remove(post.id));
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final displayedPosts = [..._posts]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    displayedPosts.removeWhere((post) => post.audience != _selectedAudience);
    final query = _searchQuery.trim().toLowerCase();
    if (query.isNotEmpty) {
      displayedPosts.removeWhere(
        (post) =>
            !post.content.toLowerCase().contains(query) &&
            !post.authorName.toLowerCase().contains(query),
      );
    }
    final emptyMessage = query.isNotEmpty
        ? 'No posts match “${_searchQuery.trim()}”.'
        : _posts.isEmpty
        ? 'No posts yet.'
        : switch (_selectedAudience) {
            'friends' => 'No friends-only posts yet.',
            'only_me' => 'No private posts yet.',
            _ => 'No public posts yet.',
          };
    final title = _isOwner
        ? 'My Posts'
        : '${widget.displayName.trim().isEmpty ? 'User' : widget.displayName.trim()}’s Posts';

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          tooltip: 'Back',
          onPressed: () => context.canPop() ? context.pop() : null,
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.article_outlined,
                      color: Color(0xFF1769E0),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_posts.length} ${_posts.length == 1 ? 'post' : 'posts'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_isOwner)
                      FilledButton.icon(
                        onPressed: _creating ? null : _createPost,
                        icon: const Icon(Icons.add, size: 18),
                        label: Text(_creating ? 'Publishing…' : 'New Post'),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1769E0),
                          shape: const StadiumBorder(),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _loading ? 'Loading posts…' : 'All published & active',
                    style: const TextStyle(
                      color: Color(0xFF687684),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              maxLength: 100,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search your posts...',
                counterText: '',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF1769E0)),
                suffixIcon: _searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Clear search',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.close),
                      ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1769E0)),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _AudienceTabs(
              selectedAudience: _selectedAudience,
              onSelected: (audience) {
                setState(() => _selectedAudience = audience);
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const LoadingView()
                : _loadError != null
                ? _ErrorState(
                    message: _loadError.toString(),
                    onRetry: _loadPosts,
                  )
                : RefreshIndicator(
                    onRefresh: _loadPosts,
                    child: displayedPosts.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              Center(child: Text(emptyMessage)),
                            ],
                          )
                        : ListView.separated(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                            itemCount: displayedPosts.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: 12),
                            itemBuilder: (context, index) {
                              final post = displayedPosts[index];
                              return _PostCard(
                                post: post,
                                isOwner: _isOwner,
                                busy: _busyPosts.contains(post.id),
                                onInsights: () => _showInsights(post),
                                onEdit: () => _editPost(post),
                                onDelete: () => _deletePost(post),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _AudienceTabs extends StatelessWidget {
  const _AudienceTabs({
    required this.selectedAudience,
    required this.onSelected,
  });

  final String selectedAudience;
  final ValueChanged<String> onSelected;

  static const _audiences = [
    ('public', 'Public'),
    ('friends', 'Friends'),
    ('only_me', 'Only me'),
  ];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: const Color(0xFFE9EFFB),
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        for (final (audience, label) in _audiences)
          Expanded(
            child: Semantics(
              button: true,
              selected: selectedAudience == audience,
              child: InkWell(
                borderRadius: BorderRadius.circular(11),
                onTap: () => onSelected(audience),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: selectedAudience == audience
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(
                      color: selectedAudience == audience
                          ? const Color(0xFF1769E0)
                          : const Color(0xFF596579),
                      fontSize: 13,
                      fontWeight: selectedAudience == audience
                          ? FontWeight.w700
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.isOwner,
    required this.busy,
    required this.onInsights,
    required this.onEdit,
    required this.onDelete,
  });

  final ManagedPost post;
  final bool isOwner;
  final bool busy;
  final VoidCallback onInsights;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final initials = post.authorName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFE5EEFF),
                        child: Text(
                          initials,
                          style: const TextStyle(
                            color: Color(0xFF1769E0),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              post.authorName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            Text(
                              _formatTimeAgo(post.createdAt),
                              style: const TextStyle(
                                color: Color(0xFF687684),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEFF5FF),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          switch (post.audience) {
                            'friends' => 'Friends',
                            'only_me' => 'Only me',
                            _ => 'Public',
                          },
                          style: const TextStyle(
                            color: Color(0xFF3575D3),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    post.content,
                    style: const TextStyle(fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: Color(0xFF687684),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.likes} Likes',
                        style: const TextStyle(
                          color: Color(0xFF687684),
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chat_bubble_outline,
                        size: 17,
                        color: Color(0xFF687684),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${post.comments} Comments',
                        style: const TextStyle(
                          color: Color(0xFF687684),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (isOwner)
              Container(
                color: const Color(0xFFF0F4FF),
                child: Row(
                  children: [
                    _PostAction(
                      icon: Icons.bar_chart_rounded,
                      label: 'Insights',
                      color: const Color(0xFF1769E0),
                      onPressed: busy ? null : onInsights,
                    ),
                    _PostAction(
                      icon: Icons.edit_outlined,
                      label: 'Edit',
                      color: const Color(0xFF374151),
                      onPressed: busy ? null : onEdit,
                    ),
                    _PostAction(
                      icon: Icons.delete_outline,
                      label: 'Delete',
                      color: const Color(0xFFC63838),
                      onPressed: busy ? null : onDelete,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  static String _formatTimeAgo(DateTime createdAt) {
    final difference = DateTime.now().difference(createdAt);
    if (difference.isNegative || difference.inMinutes == 0) return 'just now';
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    }
    if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    }
    return '${difference.inMinutes} min ago';
  }
}

class _PostAction extends StatelessWidget {
  const _PostAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Expanded(
    child: TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: color, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
        shape: const RoundedRectangleBorder(),
      ),
    ),
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 42, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
