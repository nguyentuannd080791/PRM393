import '../enums/app_enums.dart';

/// 6. Notification Table Model (SDD §III.2.4)
class NotificationModel {
  final String id;
  final String recipientId;
  final String actorId;
  final String? postId;
  final NotificationType type;
  final bool isRead;
  final DateTime createdAt;

  const NotificationModel({
    required this.id,
    required this.recipientId,
    required this.actorId,
    this.postId,
    required this.type,
    this.isRead = false,
    required this.createdAt,
  });

  NotificationModel copyWith({
    String? id,
    String? recipientId,
    String? actorId,
    String? postId,
    NotificationType? type,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      recipientId: recipientId ?? this.recipientId,
      actorId: actorId ?? this.actorId,
      postId: postId ?? this.postId,
      type: type ?? this.type,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'recipient_id': recipientId,
    'actor_id': actorId,
    'post_id': postId,
    'type': type.toDbString(),
    'is_read': isRead,
    'created_at': createdAt.toIso8601String(),
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'].toString(),
    recipientId: json['recipient_id'].toString(),
    actorId: json['actor_id'].toString(),
    postId: json['post_id']?.toString(),
    type: NotificationType.fromString(json['type'] as String),
    isRead: json['is_read'] as bool? ?? false,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  @override
  bool operator ==(Object other) => identical(this, other) || other is NotificationModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
