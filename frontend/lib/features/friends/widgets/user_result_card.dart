import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/widgets/user_avatar.dart';

import '../models/user_result.dart';
import '../providers/friends_provider.dart';
import 'friends_ui.dart';

class UserResultCard extends ConsumerWidget {
  const UserResultCard(this.user, {super.key});
  final UserResult user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final busy = ref
        .watch(friendshipActionsProvider)
        .contains('user:${user.id}');
    final actions = ref.read(friendshipActionsProvider.notifier);
    void openProfile() => context.push(AppRoutePaths.profilePath(user.id));
    Widget button;
    switch (user.relationship) {
      case 'friends':
        button = ActionChip(
          avatar: const Icon(Icons.check, size: 16, color: Color(0xFF006646)),
          backgroundColor: const Color(0xFF88F8C4),
          side: BorderSide.none,
          label: const Text(
            'Friends',
            style: TextStyle(color: Color(0xFF006646)),
          ),
          onPressed: openProfile,
        );
      case 'pending_sent':
        button = ActionChip(
          avatar: const Icon(Icons.schedule, size: 16, color: socialBlue),
          label: const Text('Request Sent'),
          backgroundColor: const Color(0xFFDBE3F0),
          side: BorderSide.none,
          onPressed: () =>
              context.push('${AppRoutePaths.friendRequests}?tab=sent'),
        );
      case 'pending_received':
        button = OutlinedButton(
          onPressed: () => context.push(AppRoutePaths.friendRequests),
          child: const Text('Respond to Request'),
        );
      default:
        button = FilledButton.icon(
          onPressed: busy
              ? null
              : () => socialAction(
                  context,
                  () => actions.send(user.id),
                  'Friend request sent.',
                ),
          icon: busy
              ? const ActionSpinner()
              : const Icon(Icons.person_add_alt_1, size: 17),
          label: const Text('Add Friend'),
        );
    }
    return SocialCard(
      padding: const EdgeInsets.all(14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final identity = InkWell(
            onTap: openProfile,
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                UserAvatar(user.name),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (user.bio?.isNotEmpty ?? false)
                        Text(
                          user.bio!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: socialMuted,
                            fontSize: 13,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          );
          if (constraints.maxWidth < 300) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                identity,
                const SizedBox(height: 12),
                Align(alignment: Alignment.centerRight, child: button),
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: identity),
              const SizedBox(width: 12),
              button,
            ],
          );
        },
      ),
    );
  }
}
