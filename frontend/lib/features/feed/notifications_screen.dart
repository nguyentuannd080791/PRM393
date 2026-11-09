import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/widgets/loading_view.dart';
import 'package:clone_facebook/core/widgets/user_avatar.dart';
import 'package:clone_facebook/features/friends/widgets/friends_ui.dart';

import 'feed_provider.dart';
import 'models/feed_models.dart';

/// SCR03: the signed-in user's recent activity.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _open(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) async {
    if (!item.isRead) {
      try {
        await markNotificationRead(ref, item.id);
      } catch (_) {
        // Opening the related content still works if the read mark failed.
      }
    }
    if (!context.mounted) return;
    final postId = item.postId;
    if (postId != null) {
      context.push(AppRoutePaths.postDetailPath(postId));
    } else if (item.kind == NotificationKind.friendRequest) {
      context.push(AppRoutePaths.friendRequests);
    } else {
      context.push(AppRoutePaths.profilePath(item.actor.id));
    }
  }

  List<Widget> _sections(
    BuildContext context,
    WidgetRef ref,
    NotificationList data,
  ) {
    final unread = data.items.where((n) => !n.isRead).toList();
    final earlier = data.items.where((n) => n.isRead).toList();
    return [
      Row(
        children: [
          const Text(
            'Recent',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          if (data.unread > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: socialBlue,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${data.unread} new',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const Spacer(),
          TextButton.icon(
            onPressed: data.unread == 0
                ? null
                : () => socialAction(
                    context,
                    () => markAllNotificationsRead(ref),
                    'All notifications marked as read.',
                  ),
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Mark all read'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      for (final item in unread) _tile(context, ref, item),
      if (earlier.isNotEmpty) ...[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Text(
            'EARLIER',
            style: TextStyle(
              color: socialMuted,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final item in earlier) _tile(context, ref, item),
      ],
    ];
  }

  IconData _badge(NotificationKind kind) => switch (kind) {
    NotificationKind.reaction => Icons.favorite,
    NotificationKind.comment => Icons.chat_bubble,
    NotificationKind.friendRequest => Icons.person_add,
    NotificationKind.friendAccept => Icons.how_to_reg,
  };

  Widget _tile(
    BuildContext context,
    WidgetRef ref,
    NotificationItem item,
  ) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Material(
      color: item.isRead ? Colors.white : const Color(0xFFF2F6FF),
      borderRadius: BorderRadius.circular(14),
      elevation: 0.5,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(context, ref, item),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  UserAvatar(item.actor.name, radius: 20),
                  Positioned(
                    right: -4,
                    bottom: -4,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: item.isRead ? socialMuted : socialBlue,
                      child: Icon(
                        _badge(item.kind),
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.message),
                    const SizedBox(height: 2),
                    Text(
                      requestTime(item.createdAt),
                      style: const TextStyle(color: socialMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (!item.isRead)
                const Icon(Icons.circle, size: 10, color: socialBlue),
            ],
          ),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider);
    return Theme(
      data: member4Theme(),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go(AppRoutePaths.feed),
          ),
          title: const Text(
            'Notifications',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
        body: list.when(
          loading: () => const LoadingView(),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error.toString(), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(notificationsProvider),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
          data: (data) => RefreshIndicator(
            onRefresh: () => ref.refresh(notificationsProvider.future),
            child: data.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      Center(
                        child: Text(
                          'You have no notifications yet.',
                          style: TextStyle(color: socialMuted),
                        ),
                      ),
                    ],
                  )
                : ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    children: _sections(context, ref, data),
                  ),
          ),
        ),
      ),
    );
  }
}
