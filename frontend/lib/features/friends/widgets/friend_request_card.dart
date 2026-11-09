import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/widgets/user_avatar.dart';

import '../models/friend_request.dart';
import '../providers/friends_provider.dart';
import 'friends_ui.dart';

class FriendRequestCard extends ConsumerWidget {
  const FriendRequestCard({
    super.key,
    required this.request,
    required this.sent,
  });
  final FriendRequest request;
  final bool sent;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref
        .watch(friendshipActionsProvider)
        .contains('request:${request.id}');
    final actions = ref.read(friendshipActionsProvider.notifier);
    void change(String action, String message) {
      socialAction(context, () => actions.change(request.id, action), message);
    }

    return SocialCard(
      child: Column(
        children: [
          InkWell(
            onTap: () =>
                context.push(AppRoutePaths.profilePath(request.user.id)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                UserAvatar(request.user.name, radius: 22),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        sent ? 'Pending request' : 'Wants to connect with you',
                        style: const TextStyle(
                          color: socialMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  requestTime(request.createdAt),
                  style: const TextStyle(color: socialMuted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (sent)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: busy
                    ? null
                    : () => change('cancel', 'Request canceled.'),
                child: busy
                    ? const ActionSpinner()
                    : const Text('Cancel Request'),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: busy
                        ? null
                        : () => change('accept', 'Friend request accepted.'),
                    icon: busy
                        ? const ActionSpinner()
                        : const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: busy
                        ? null
                        : () => change('decline', 'Friend request declined.'),
                    style: FilledButton.styleFrom(
                      backgroundColor: socialTint,
                      foregroundColor: socialInk,
                    ),
                    child: const Text('Decline'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
