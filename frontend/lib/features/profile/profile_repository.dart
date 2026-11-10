import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/enums/app_enums.dart';
import '../../core/models/app_models.dart';
import '../../core/network/api_client.dart';
import 'domain/entities/user_profile.dart';

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<UserModel?> getProfile(String id) async {
    try {
      final profile = await getUserProfile(id);
      return profile.user;
    } catch (_) {
      return null;
    }
  }

  Future<UserProfileView> getUserProfile(String userId) async {
    final response = await _apiClient.get('/users/$userId');
    final data = response.data['data'] as Map<String, dynamic>;

    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final relStr = data['relationship_status'] as String? ?? 'none';
    final relationshipStatus = _parseRelationshipStatus(relStr);
    final friendsCount = (data['friends_count'] as num?)?.toInt() ?? 0;
    final mutualCount = (data['mutual_friends_count'] as num?)?.toInt() ?? 0;

    return UserProfileView(
      user: user,
      relationshipStatus: relationshipStatus,
      friendsCount: friendsCount,
      mutualFriendsCount: mutualCount,
    );
  }

  Future<PaginatedPostsResult> getUserPosts(String userId, {int page = 1, int limit = 10}) async {
    final response = await _apiClient.get(
      '/users/$userId/posts',
      queryParameters: {'page': page, 'limit': limit},
    );

    final dynamic bodyData = response.data['data'];
    final dynamic pagData = response.data['pagination'];

    return PaginatedPostsResult.fromJson(
      bodyData,
      paginationJson: pagData is Map<String, dynamic> ? pagData : null,
      defaultPage: page,
      defaultLimit: limit,
    );
  }

  Future<PaginatedPostsResult> getPaginatedUserPosts(String userId, {int page = 1, int limit = 10}) {
    return getUserPosts(userId, page: page, limit: limit);
  }

  Future<UserModel> updateProfile({
    String? fullName,
    String? bio,
    String? avatarUrl,
    String? coverUrl,
    String? city,
    String? workplace,
  }) async {
    final body = <String, dynamic>{};
    if (fullName != null) body['full_name'] = fullName;
    if (bio != null) body['bio'] = bio;
    if (avatarUrl != null) body['avatar_url'] = avatarUrl;
    if (coverUrl != null) body['cover_url'] = coverUrl;
    if (city != null) body['city'] = city;
    if (workplace != null) body['workplace'] = workplace;

    final response = await _apiClient.put('/users/profile', data: body);
    final data = response.data['data'] as Map<String, dynamic>;
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    return user;
  }

  UserRelationshipStatus _parseRelationshipStatus(String status) {
    switch (status.toLowerCase()) {
      case 'self':
        return UserRelationshipStatus.self;
      case 'friends':
        return UserRelationshipStatus.friends;
      case 'pending_sent':
      case 'pendingsent':
        return UserRelationshipStatus.pendingSent;
      case 'pending_received':
      case 'pendingreceived':
        return UserRelationshipStatus.pendingReceived;
      case 'none':
      default:
        return UserRelationshipStatus.none;
    }
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(apiClientProvider);
  return ProfileRepository(client);
});
