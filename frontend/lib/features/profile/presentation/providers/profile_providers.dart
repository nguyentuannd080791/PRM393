import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/models/app_models.dart';
import '../../../../data/repositories/friend_repository.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../auth/presentation/providers/auth_state_provider.dart';
import '../../domain/entities/user_profile.dart';

/// Resolves the effective target userId (mapping 'me' or empty to the viewer).
final currentViewerIdProvider = Provider<String>((ref) {
  final authUser = ref.watch(currentUserProvider);
  if (authUser != null) return authUser.id;
  return '1';
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
    final requests = await ref.watch(friendRepositoryProvider).getFriendRequests();
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

  FriendRepository get _friendRepo => _ref.read(friendRepositoryProvider);

  void _invalidate(String requestedId, String targetId) {
    _ref.invalidate(profileNotifierProvider(requestedId));
    _ref.invalidate(profileNotifierProvider(targetId));
    _ref.invalidate(profileNotifierProvider('me'));
    _ref.invalidate(pendingFriendRequestCountProvider);
  }

  Future<void> sendFriendRequest(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _friendRepo.sendFriendRequest(targetId);
    _invalidate(requestedId, targetId);
  }

  Future<void> cancelFriendRequest(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _friendRepo.cancelFriendRequest(targetId);
    _invalidate(requestedId, targetId);
  }

  Future<void> acceptFriendRequest(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _friendRepo.acceptFriendRequest(targetId);
    _invalidate(requestedId, targetId);
  }

  Future<void> rejectFriendRequest(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _friendRepo.declineFriendRequest(targetId);
    _invalidate(requestedId, targetId);
  }

  Future<void> unfriend(String requestedId) async {
    final targetId = _ref.read(effectiveUserIdProvider(requestedId));
    await _friendRepo.unfriend(targetId);
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
  return repo.getUserPosts(targetId);
});
