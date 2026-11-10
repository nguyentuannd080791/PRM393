import 'package:clone_facebook/core/enums/app_enums.dart';
import 'package:clone_facebook/core/models/app_models.dart';

/// Presentation model representing a complete user profile view.
class UserProfileView {
  final UserModel user;
  final UserRelationshipStatus relationshipStatus;
  final int friendsCount;
  final int mutualFriendsCount;

  const UserProfileView({
    required this.user,
    required this.relationshipStatus,
    this.friendsCount = 0,
    this.mutualFriendsCount = 0,
  });

  UserProfileView copyWith({
    UserModel? user,
    UserRelationshipStatus? relationshipStatus,
    int? friendsCount,
    int? mutualFriendsCount,
  }) {
    return UserProfileView(
      user: user ?? this.user,
      relationshipStatus: relationshipStatus ?? this.relationshipStatus,
      friendsCount: friendsCount ?? this.friendsCount,
      mutualFriendsCount: mutualFriendsCount ?? this.mutualFriendsCount,
    );
  }
}
