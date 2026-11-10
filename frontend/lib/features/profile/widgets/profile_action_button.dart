import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/core/enums/app_enums.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/features/profile/providers/profile_provider.dart';

class ProfileActionButton extends ConsumerStatefulWidget {
  final String userId;
  final UserRelationshipStatus status;

  const ProfileActionButton({
    super.key,
    required this.userId,
    required this.status,
  });

  @override
  ConsumerState<ProfileActionButton> createState() => _ProfileActionButtonState();
}

class _ProfileActionButtonState extends ConsumerState<ProfileActionButton> {
  bool _isSubmitting = false;

  Future<void> _confirmUnfriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unfriend'),
        content: const Text('Remove this person from your friends?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm_unfriend_button'),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Unfriend'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _isSubmitting = true);
    try {
      await ref.read(profileControllerProvider).unfriend(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend removed.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(profileControllerProvider);

    switch (widget.status) {
      case UserRelationshipStatus.self:
        return FilledButton.tonalIcon(
          key: const Key('profile_edit_button'),
          onPressed: () => context.push(AppRoutePaths.profileEdit),
          icon: const Icon(Icons.edit, size: 18),
          label: const Text('Edit Profile'),
        );

      case UserRelationshipStatus.none:
        return FilledButton.icon(
          key: const Key('profile_add_friend_button'),
          onPressed: _isSubmitting
              ? null
              : () async {
                  setState(() => _isSubmitting = true);
                  try {
                    await controller.sendFriendRequest(widget.userId);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Friend request sent.')),
                      );
                    }
                  } finally {
                    if (mounted) setState(() => _isSubmitting = false);
                  }
                },
          icon: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add, size: 18),
          label: const Text('Add Friend'),
        );

      case UserRelationshipStatus.pendingSent:
        return FilledButton.tonalIcon(
          key: const Key('profile_cancel_request_button'),
          onPressed: () async {
            await controller.cancelFriendRequest(widget.userId);
          },
          icon: const Icon(Icons.person_remove_outlined, size: 18),
          label: const Text('Cancel Request'),
        );

      case UserRelationshipStatus.pendingReceived:
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const Key('profile_accept_request_button'),
                onPressed: () async {
                  await controller.acceptFriendRequest(widget.userId);
                },
                icon: const Icon(Icons.check, size: 18),
                label: const Text('Accept'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const Key('profile_delete_request_button'),
                onPressed: () async {
                  await controller.rejectFriendRequest(widget.userId);
                },
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Decline'),
              ),
            ),
          ],
        );

      case UserRelationshipStatus.friends:
        return PopupMenuButton<String>(
          key: const Key('profile_friends_menu_button'),
          enabled: !_isSubmitting,
          tooltip: 'Friend options',
          onSelected: (value) {
            if (value == 'unfriend') _confirmUnfriend();
          },
          itemBuilder: (ctx) => const [
            PopupMenuItem(
              value: 'unfriend',
              child: Row(
                children: [
                  Icon(Icons.person_remove, size: 18),
                  SizedBox(width: 8),
                  Text('Unfriend'),
                ],
              ),
            ),
          ],
          child: Chip(
            key: const Key('profile_friends_status'),
            avatar: _isSubmitting
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.check, size: 18),
            label: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Friends'),
                SizedBox(width: 2),
                Icon(Icons.arrow_drop_down, size: 18),
              ],
            ),
          ),
        );
    }
  }
}
