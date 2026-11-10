import 'friendship_model.dart';
import 'user_model.dart';

/// Joined Friend Request item with requester info and mutual friends count.
class FriendRequestView {
  final FriendshipModel friendship;
  final UserModel requester;
  final int mutualFriendsCount;

  const FriendRequestView({
    required this.friendship,
    required this.requester,
    required this.mutualFriendsCount,
  });

  factory FriendRequestView.fromJson(Map<String, dynamic> json) {
    final friendshipData = json.containsKey('friendship') && json['friendship'] is Map<String, dynamic>
        ? json['friendship'] as Map<String, dynamic>
        : json;
    return FriendRequestView(
      friendship: FriendshipModel.fromJson(friendshipData),
      requester: UserModel.fromJson(json['requester'] as Map<String, dynamic>),
      mutualFriendsCount: (json['mutual_friends_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'friendship': friendship.toJson(),
    'requester': requester.toJson(),
    'mutual_friends_count': mutualFriendsCount,
  };
}
