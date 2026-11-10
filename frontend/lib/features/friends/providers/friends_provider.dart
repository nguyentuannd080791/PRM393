import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';

import '../repositories/friends_repository.dart';
import '../models/friend_request.dart';
import 'search_provider.dart';

Future<List<FriendRequest>> _connections(Ref ref, String kind) async {
  if (ref.watch(sessionUserIdProvider) == null) return const [];
  // Refresh other-device changes while a screen is visible. No sockets required.
  final timer = Timer(const Duration(seconds: 15), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  return ref.watch(friendsRepositoryProvider).connections(kind);
}

final friendsProvider = FutureProvider.autoDispose<List<FriendRequest>>(
  (ref) => _connections(ref, 'friends'),
);
final receivedRequestsProvider =
    FutureProvider.autoDispose<List<FriendRequest>>(
      (ref) => _connections(ref, 'received'),
    );
final sentRequestsProvider = FutureProvider.autoDispose<List<FriendRequest>>(
  (ref) => _connections(ref, 'sent'),
);

class FriendFilter extends Notifier<String> {
  @override
  String build() {
    ref.watch(sessionUserIdProvider);
    return '';
  }

  void setQuery(String value) => state = value;
}

final friendFilterProvider = NotifierProvider<FriendFilter, String>(
  FriendFilter.new,
);

class FriendshipActions extends Notifier<Set<String>> {
  @override
  Set<String> build() {
    ref.watch(sessionUserIdProvider);
    return {};
  }

  Future<void> send(String userId) => _run(
    'user:$userId',
    () => ref.read(friendsRepositoryProvider).sendRequest(userId),
  );

  Future<void> change(String id, String action) => _run(
    'request:$id',
    () => ref.read(friendsRepositoryProvider).changeRequest(id, action),
  );

  Future<void> cancel(String targetUserIdOrRequestId) async {
    final sent = await ref.read(sentRequestsProvider.future);
    final match = sent
        .where((r) => r.id == targetUserIdOrRequestId || r.user.id == targetUserIdOrRequestId)
        .firstOrNull;
    final id = match != null ? match.id : targetUserIdOrRequestId;
    await change(id, 'cancel');
  }

  Future<void> accept(String targetUserIdOrRequestId) async {
    final received = await ref.read(receivedRequestsProvider.future);
    final match = received
        .where((r) => r.id == targetUserIdOrRequestId || r.user.id == targetUserIdOrRequestId)
        .firstOrNull;
    final id = match != null ? match.id : targetUserIdOrRequestId;
    await change(id, 'accept');
  }

  Future<void> reject(String targetUserIdOrRequestId) async {
    final received = await ref.read(receivedRequestsProvider.future);
    final match = received
        .where((r) => r.id == targetUserIdOrRequestId || r.user.id == targetUserIdOrRequestId)
        .firstOrNull;
    final id = match != null ? match.id : targetUserIdOrRequestId;
    await change(id, 'decline');
  }

  Future<void> _run(String key, Future<void> Function() action) async {
    if (state.contains(key)) return;
    state = {...state, key};
    try {
      await action();
    } finally {
      if (ref.mounted) {
        ref.invalidate(friendsProvider);
        ref.invalidate(receivedRequestsProvider);
        ref.invalidate(sentRequestsProvider);
        // Reconcile even on a 409 from another device acting first.
        await ref.read(member4SearchProvider.notifier).refresh();
        if (ref.mounted) state = {...state}..remove(key);
      }
    }
  }
}

final friendshipActionsProvider =
    NotifierProvider<FriendshipActions, Set<String>>(FriendshipActions.new);
