import 'user_result.dart';

class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.user,
    required this.createdAt,
    this.acceptedAt,
  });
  final String id;
  final UserResult user;
  final DateTime createdAt;
  final DateTime? acceptedAt;

  factory FriendRequest.fromJson(Map<String, dynamic> json) => FriendRequest(
    id: json['id'] as String,
    user: UserResult.fromJson(json['user'] as Map<String, dynamic>),
    createdAt: DateTime.parse(json['created_at'] as String),
    acceptedAt: DateTime.tryParse(json['responded_at'] as String? ?? ''),
  );
}
