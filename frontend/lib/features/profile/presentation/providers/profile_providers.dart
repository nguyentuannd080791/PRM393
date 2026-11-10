import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/app_models.dart';
import '../../../auth/auth_provider.dart';
import '../../domain/entities/user_profile.dart';
import '../../profile_repository.dart';
import '../../../feed/feed_provider.dart';
import '../../../friends/providers/friends_provider.dart';

/// Resolves the effective target userId (mapping 'me' or empty to the viewer).
final currentViewerIdProvider = Provider<String>((ref) {
  final authUser = ref.watch(currentUserProvider);
  if (authUser != null) return authUser.id;
  return '';
});

/// Resolves requested userId ('me' -> viewerId).
final effectiveUserIdProvider = Provider.family<String, String>((ref, requestedId) {
  if (requestedId == 'me' || requestedId.isEmpty) {
    return ref.watch(currentViewerIdProvider);
  }
  return requestedId;
});

/// Pending friend request count badge provider.
final pendingFriendRequestCountProvider = FutureProvider<int>((ref) async {
  try {
    final requests = await ref.watch(receivedRequestsProvider.future);
    return requests.length;
  } catch (_) {
    return 0;
  }
});

/// Profile View Provider per user.
final profileNotifierProvider =
    FutureProvider.family<UserProfileView, String>((ref, requestedId) async {
  final targetId = ref.watch(effectiveUserIdProvider(requestedId));
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getUserProfile(targetId);
});

/// Controller handling friendship actions for profiles.
class ProfileController {
  final Ref _ref;

  const ProfileController(this._ref);

  void _invalidate(String requestedId, String targetId) {
    _ref.invalidate(profileNotifierProvider(requestedId));
    _ref.invalidate(profileNotifierProvider(targetId));
    _ref.invalidate(profileNotifierProvider('me'));
    _ref.invalidate(pendingFriendRequestCountProvider);
    _ref.invalidate(friendsProvider);
    _ref.invalidate(receivedRequestsProvider);
    _ref.invalidate(sentRequestsProvider);
  }

  Future<void> sendFriendRequest(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _ref.read(friendshipActionsProvider.notifier).send(targetId);
    _invalidate(requestedId, targetId);
  }

  Future<void> cancelFriendRequest(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _ref.read(friendshipActionsProvider.notifier).cancel(targetId);
    _invalidate(requestedId, targetId);
  }

  Future<void> acceptFriendRequest(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _ref.read(friendshipActionsProvider.notifier).accept(targetId);
    _invalidate(requestedId, targetId);
  }

  /// Ends an accepted friendship. Friends-only posts disappear from the feed and the profile.
  Future<void> unfriend(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _ref.read(friendshipActionsProvider.notifier).unfriend(targetId);
    _invalidate(requestedId, targetId);
    _ref.invalidate(profilePostsProvider(requestedId));
    _ref.invalidate(profilePostsProvider(targetId));
    _ref.invalidate(feedProvider);
  }

  Future<void> rejectFriendRequest(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _ref.read(friendshipActionsProvider.notifier).reject(targetId);
    _invalidate(requestedId, targetId);
  }
}

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});

/// Posts authored by the target user.
final profilePostsProvider =
    FutureProvider.family<List<FeedPostView>, String>((ref, requestedId) async {
  final targetId = ref.watch(effectiveUserIdProvider(requestedId));
  final repo = ref.watch(profileRepositoryProvider);
  final result = await repo.getUserPosts(targetId);
  return result.posts;
});
