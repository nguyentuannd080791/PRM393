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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final list = ref.watch(notificationsProvider);
    final unread = list.asData?.value.unread ?? 0;
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
          actions: [
            TextButton(
              onPressed: unread == 0
                  ? null
                  : () => socialAction(
                      context,
                      () => markAllNotificationsRead(ref),
                      'All notifications marked as read.',
                    ),
              child: const Text('Mark all read'),
            ),
          ],
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
                : ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: data.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final item = data.items[i];
                      return ListTile(
                        tileColor: item.isRead ? null : socialTint,
                        leading: UserAvatar(item.actor.name),
                        title: Text(
                          item.message,
                          style: TextStyle(
                            fontWeight: item.isRead
                                ? FontWeight.w400
                                : FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(requestTime(item.createdAt)),
                        trailing: item.isRead
                            ? null
                            : const Icon(
                                Icons.circle,
                                size: 10,
                                color: socialBlue,
                              ),
                        onTap: () => _open(context, ref, item),
                      );
                    },
                  ),
          ),
        ),
      ),
    );
  }
}
