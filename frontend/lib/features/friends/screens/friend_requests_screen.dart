import 'package:clone_facebook/core/widgets/loading_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/friends_provider.dart';
import '../widgets/friends_ui.dart';
import '../widgets/friend_request_card.dart';

/// SCR11: Received and Sent are tabs, not separate pages.
class FriendRequestsScreen extends ConsumerStatefulWidget {
  const FriendRequestsScreen({super.key, this.initialSent = false});
  final bool initialSent;
  @override
  ConsumerState<FriendRequestsScreen> createState() =>
      _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends ConsumerState<FriendRequestsScreen> {
  late bool _sent;
  @override
  void initState() {
    super.initState();
    _sent = widget.initialSent;
  }

  @override
  Widget build(BuildContext context) {
    final received = ref.watch(receivedRequestsProvider);
    final sent = ref.watch(sentRequestsProvider);
    final currentProvider = _sent
        ? sentRequestsProvider
        : receivedRequestsProvider;
    final current = _sent ? sent : received;
    return Member4Scaffold(
      title: 'Friend Requests',
      brand: false,
      body: RefreshIndicator(
        onRefresh: () async {
          final pending = ref.refresh(currentProvider.future);
          await pending;
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            SocialSegments(
              labels: [
                'Received${received.asData == null ? '' : '  ${received.asData!.value.length}'}',
                'Sent${sent.asData == null ? '' : '  ${sent.asData!.value.length}'}',
              ],
              selected: _sent ? 1 : 0,
              onSelected: (index) => setState(() => _sent = index == 1),
            ),
            const SizedBox(height: 20),
            current.when(
              loading: () => const LoadingView(),
              error: (error, _) => SocialMessage(
                error.toString(),
                icon: Icons.cloud_off,
                onRetry: () => ref.invalidate(currentProvider),
              ),
              data: (items) => items.isEmpty
                  ? SocialMessage(
                      _sent
                          ? 'No pending sent requests.'
                          : 'No pending received requests.',
                    )
                  : Column(
                      children: [
                        for (final request in items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: FriendRequestCard(
                              request: request,
                              sent: _sent,
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
