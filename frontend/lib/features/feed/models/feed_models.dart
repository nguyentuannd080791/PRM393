class FeedUser {
  const FeedUser({required this.id, required this.name});
  final String id;
  final String name;

  factory FeedUser.fromJson(Map<String, dynamic> json) => FeedUser(
    id: json['id'] as String,
    name: json['full_name'] as String? ?? 'Unknown user',
  );
}

class FeedPost {
  const FeedPost({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    this.likeCount = 0,
    this.commentCount = 0,
    this.likedByMe = false,
    this.savedByMe = false,
  });
  final String id;
  final FeedUser author;
  final String content;
  final DateTime createdAt;
  final int likeCount;
  final int commentCount;
  final bool likedByMe;
  final bool savedByMe;

  factory FeedPost.fromJson(Map<String, dynamic> json) => FeedPost(
    id: json['id'] as String,
    author: FeedUser.fromJson(json['author'] as Map<String, dynamic>),
    content: json['content'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    likeCount: json['like_count'] as int? ?? 0,
    commentCount: json['comment_count'] as int? ?? 0,
    likedByMe: json['liked_by_me'] as bool? ?? false,
    savedByMe: json['saved_by_me'] as bool? ?? false,
  );
}

class FeedPage {
  const FeedPage({required this.posts, required this.hasMore});
  final List<FeedPost> posts;
  final bool hasMore;
}

enum NotificationKind { reaction, comment, friendRequest, friendAccept }

class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.kind,
    required this.actor,
    required this.createdAt,
    required this.isRead,
    this.postId,
  });
  final String id;
  final NotificationKind kind;
  final FeedUser actor;
  final DateTime createdAt;
  final bool isRead;
  final String? postId;

  String get message => switch (kind) {
    NotificationKind.reaction => '${actor.name} liked your post.',
    NotificationKind.comment => '${actor.name} commented on your post.',
    NotificationKind.friendRequest =>
      '${actor.name} sent you a friend request.',
    NotificationKind.friendAccept =>
      '${actor.name} accepted your friend request.',
  };

  factory NotificationItem.fromJson(Map<String, dynamic> json) =>
      NotificationItem(
        id: json['id'] as String,
        kind: switch (json['type']) {
          'comment' => NotificationKind.comment,
          'friend_request' => NotificationKind.friendRequest,
          'friend_accept' => NotificationKind.friendAccept,
          _ => NotificationKind.reaction,
        },
        actor: FeedUser.fromJson(json['actor'] as Map<String, dynamic>),
        createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
        isRead: json['is_read'] as bool? ?? false,
        postId: json['post_id'] as String?,
      );
}

class NotificationList {
  const NotificationList({required this.items, required this.unread});
  final List<NotificationItem> items;
  final int unread;
}
