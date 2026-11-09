import 'package:clone_facebook/core/widgets/loading_view.dart';
import 'package:clone_facebook/core/widgets/user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:clone_facebook/app/route_names.dart';

import '../providers/friends_provider.dart';
import '../widgets/friends_ui.dart';

/// SCR12: accepted, mutual friendships with a local name filter.
class FriendListScreen extends ConsumerStatefulWidget {
  const FriendListScreen({super.key});
  @override
  ConsumerState<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends ConsumerState<FriendListScreen> {
  late final TextEditingController _filter;
  @override
  void initState() {
    super.initState();
    _filter = TextEditingController(text: ref.read(friendFilterProvider));
  }

  @override
  void dispose() {
    _filter.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friends = ref.watch(friendsProvider);
    final incoming = ref.watch(receivedRequestsProvider).asData?.value.length;
    final query = ref.watch(friendFilterProvider).trim().toLowerCase();
    return Member4Scaffold(
      title: 'Friends',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(receivedRequestsProvider);
          final pending = ref.refresh(friendsProvider.future);
          await pending;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Text(
                  '${friends.asData?.value.length ?? 0} Friends',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => context.push(AppRoutePaths.friendRequests),
                  style: FilledButton.styleFrom(
                    backgroundColor: socialBlue,
                    shape: const StadiumBorder(),
                  ),
                  icon: const Icon(Icons.person_add_alt_1, size: 20),
                  label: Text(
                    'Requests${incoming == null ? '' : '  $incoming'}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _filter,
              onChanged: ref.read(friendFilterProvider.notifier).setQuery,
              decoration: const InputDecoration(
                hintText: 'Search friends...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 16),
            friends.when(
              loading: () => const LoadingView(),
              error: (error, _) => SocialMessage(
                error.toString(),
                icon: Icons.cloud_off,
                onRetry: () => ref.invalidate(friendsProvider),
              ),
              data: (items) {
                final filtered = items
                    .where(
                      (item) => item.user.name.toLowerCase().contains(query),
                    )
                    .toList();
                if (filtered.isEmpty) {
                  return SocialMessage(
                    items.isEmpty
                        ? 'No friends yet. Search people and send your first request.'
                        : 'No friends match your search.',
                  );
                }
                return SocialCard(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      for (final friend in filtered)
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: UserAvatar(friend.user.name, radius: 22),
                          title: Text(
                            friend.user.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            friendSince(friend.acceptedAt ?? friend.createdAt),
                            style: const TextStyle(
                              color: socialMuted,
                              fontSize: 13,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: socialMuted,
                          ),
                          onTap: () => context.push(
                            AppRoutePaths.profilePath(friend.user.id),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'Tap any friend to view their ideas & profile',
                textAlign: TextAlign.center,
                style: TextStyle(color: socialMuted, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
