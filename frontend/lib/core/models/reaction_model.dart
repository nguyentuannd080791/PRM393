import '../enums/app_enums.dart';

/// 4. Reaction Table Model (Composite PK: post_id + user_id) (SDD §III.2.4)
class ReactionModel {
  final String postId;
  final String userId;
  final ReactionType type;
  final DateTime createdAt;

  const ReactionModel({
    required this.postId,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  ReactionModel copyWith({
    String? postId,
    String? userId,
    ReactionType? type,
    DateTime? createdAt,
  }) {
    return ReactionModel(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'post_id': postId,
    'user_id': userId,
    'type': type.name,
    'created_at': createdAt.toIso8601String(),
  };

  factory ReactionModel.fromJson(Map<String, dynamic> json) => ReactionModel(
    postId: json['post_id'].toString(),
    userId: json['user_id'].toString(),
    type: ReactionType.fromString(json['type'] as String) ?? ReactionType.like,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReactionModel && postId == other.postId && userId == other.userId;

  @override
  int get hashCode => Object.hash(postId, userId);
}
