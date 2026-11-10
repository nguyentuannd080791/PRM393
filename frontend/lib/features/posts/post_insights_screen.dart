import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/loading_view.dart';
import 'posts_repository.dart';

class PostInsightsScreen extends ConsumerStatefulWidget {
  const PostInsightsScreen({super.key, required this.postId});

  final String postId;

  @override
  ConsumerState<PostInsightsScreen> createState() => _PostInsightsScreenState();
}

class _PostInsightsScreenState extends ConsumerState<PostInsightsScreen> {
  Map<String, dynamic>? _insights;
  Object? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await ref
          .read(postsRepositoryProvider)
          .getInsights(widget.postId);
      if (!mounted) return;
      setState(() {
        _insights = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF6F8FC),
    appBar: AppBar(
      backgroundColor: const Color(0xFFF6F8FC),
      leading: IconButton(
        tooltip: 'Back',
        onPressed: () => context.pop(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded),
      ),
      title: const Text(
        'Post Insights',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
      actions: const [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: CircleAvatar(
            radius: 15,
            backgroundColor: Color(0xFF1769E0),
            child: Icon(Icons.person, color: Colors.white, size: 19),
          ),
        ),
      ],
    ),
    body: _loading
        ? const LoadingView()
        : _error != null
        ? _InsightError(message: _error.toString(), onRetry: _loadInsights)
        : _buildContent(_insights ?? const {}),
  );

  Widget _buildContent(Map<String, dynamic> data) {
    final author = data['author'] as Map<String, dynamic>? ?? const {};
    final name = author['full_name'] as String? ?? 'You';
    final content = data['content'] as String? ?? '';
    final createdAt = DateTime.tryParse(data['created_at'] as String? ?? '');
    final activities = (data['recent_activity'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final likes = data['likes'] as int? ?? 0;
    final comments = data['comments'] as int? ?? 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _InitialAvatar(name: name),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          'Posted ${createdAt == null ? '' : _formatTimeAgo(createdAt)}',
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
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FF),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Text(
                      'Author view',
                      style: TextStyle(
                        color: Color(0xFF1769E0),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              if (content.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '“$content”',
                    style: const TextStyle(
                      color: Color(0xFF526071),
                      fontStyle: FontStyle.italic,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                icon: Icons.favorite,
                iconColor: const Color(0xFFE33D48),
                value: likes,
                label: 'Likes',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                icon: Icons.chat_bubble,
                iconColor: const Color(0xFF1769E0),
                value: comments,
                label: 'Comments',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Recent Activity',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (activities.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'No activity yet.',
                    style: TextStyle(color: Color(0xFF687684)),
                  ),
                )
              else
                for (final activity in activities)
                  _ActivityRow(activity: activity),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 46,
          child: FilledButton(
            onPressed: () => context.pop(),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE7EEFF),
              foregroundColor: const Color(0xFF1769E0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Open Post'),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward, size: 18),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

String _formatTimeAgo(DateTime date) {
  final difference = DateTime.now().difference(date);
  if (difference.isNegative || difference.inMinutes == 0) return 'just now';
  if (difference.inDays > 0) return '${difference.inDays} day ago';
  if (difference.inHours > 0) return '${difference.inHours}h ago';
  if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
  return 'just now';
}

class _InitialAvatar extends StatelessWidget {
  const _InitialAvatar({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();
    return CircleAvatar(
      radius: 18,
      backgroundColor: const Color(0xFFE5EEFF),
      child: Text(
        initials,
        style: const TextStyle(
          color: Color(0xFF1769E0),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final Color iconColor;
  final int value;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 17,
          backgroundColor: iconColor.withValues(alpha: 0.12),
          child: Icon(icon, size: 19, color: iconColor),
        ),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        Text(label, style: const TextStyle(color: Color(0xFF687684))),
      ],
    ),
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final Map<String, dynamic> activity;

  @override
  Widget build(BuildContext context) {
    final name = activity['actor_name'] as String? ?? 'Someone';
    final action = activity['action'] as String? ?? 'liked';
    final createdAt = DateTime.tryParse(
      activity['created_at'] as String? ?? '',
    );
    final liked = action == 'liked';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              _InitialAvatar(name: name),
              Positioned(
                right: -2,
                bottom: -2,
                child: CircleAvatar(
                  radius: 8,
                  backgroundColor: liked
                      ? const Color(0xFFFFE7E8)
                      : const Color(0xFFE8F0FF),
                  child: Icon(
                    liked ? Icons.favorite : Icons.chat_bubble,
                    size: 9,
                    color: liked
                        ? const Color(0xFFE33D48)
                        : const Color(0xFF1769E0),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$name ${liked ? 'liked' : 'commented on'} your post',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  createdAt == null ? '' : _formatTimeAgo(createdAt),
                  style: const TextStyle(
                    color: Color(0xFF687684),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightError extends StatelessWidget {
  const _InsightError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Try again')),
        ],
      ),
    ),
  );
}
