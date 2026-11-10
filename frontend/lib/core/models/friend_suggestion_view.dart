import 'user_model.dart';

/// Friend Suggestion item with mutual friends count.
class FriendSuggestionView {
  final UserModel user;
  final int mutualFriendsCount;

  const FriendSuggestionView({
    required this.user,
    required this.mutualFriendsCount,
  });

  factory FriendSuggestionView.fromJson(Map<String, dynamic> json) {
    final userData = json.containsKey('user') && json['user'] is Map<String, dynamic>
        ? json['user'] as Map<String, dynamic>
        : json;
    return FriendSuggestionView(
      user: UserModel.fromJson(userData),
      mutualFriendsCount: (json['mutual_friends_count'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'user': user.toJson(),
    'mutual_friends_count': mutualFriendsCount,
  };
}
