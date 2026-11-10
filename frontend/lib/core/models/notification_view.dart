import 'notification_model.dart';
import 'post_model.dart';
import 'user_model.dart';

/// Joined Notification tile with actor info and optional post link.
class NotificationView {
  final NotificationModel notification;
  final UserModel actor;
  final PostModel? post;
  final bool isTargetPostDeleted;

  const NotificationView({
    required this.notification,
    required this.actor,
    this.post,
    this.isTargetPostDeleted = false,
  });

  factory NotificationView.fromJson(Map<String, dynamic> json) {
    final notifData = json.containsKey('notification') && json['notification'] is Map<String, dynamic>
        ? json['notification'] as Map<String, dynamic>
        : json;
    return NotificationView(
      notification: NotificationModel.fromJson(notifData),
      actor: UserModel.fromJson(json['actor'] as Map<String, dynamic>),
      post: json['post'] != null && json['post'] is Map<String, dynamic>
          ? PostModel.fromJson(json['post'] as Map<String, dynamic>)
          : null,
      isTargetPostDeleted: json['is_target_post_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'notification': notification.toJson(),
    'actor': actor.toJson(),
    if (post != null) 'post': post!.toJson(),
    'is_target_post_deleted': isTargetPostDeleted,
  };
}
