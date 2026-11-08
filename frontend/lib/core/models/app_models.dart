import '../enums/app_enums.dart';

/// 1. User Table Model (SDD §III.2.4)
class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String passwordHash;
  final DateTime birthday;
  final String gender;
  final String? avatarUrl;
  final String? coverUrl;
  final String? bio;
  final String? city;
  final String? workplace;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.passwordHash,
    required this.birthday,
    required this.gender,
    this.avatarUrl,
    this.coverUrl,
    this.bio,
    this.city,
    this.workplace,
    required this.createdAt,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phone,
    String? passwordHash,
    DateTime? birthday,
    String? gender,
    String? avatarUrl,
    String? coverUrl,
    String? bio,
    String? city,
    String? workplace,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      passwordHash: passwordHash ?? this.passwordHash,
      birthday: birthday ?? this.birthday,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      coverUrl: coverUrl ?? this.coverUrl,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      workplace: workplace ?? this.workplace,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'full_name': fullName,
    'email': email,
    'phone': phone,
    'password_hash': passwordHash,
    'birthday': birthday.toIso8601String(),
    'gender': gender,
    'avatar_url': avatarUrl,
    'cover_url': coverUrl,
    'bio': bio,
    'city': city,
    'workplace': workplace,
    'created_at': createdAt.toIso8601String(),
  };

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
    id: json['id'].toString(),
    fullName: json['full_name'] as String? ?? 'Facebook User',
    email: json['email'] as String? ?? '',
    phone: json['phone'] as String?,
    passwordHash: json['password_hash'] as String? ?? '',
    birthday: json['birthday'] != null
        ? DateTime.tryParse(json['birthday'] as String) ?? DateTime(2000, 1, 1)
        : DateTime(2000, 1, 1),
    gender: json['gender'] as String? ?? 'other',
    avatarUrl: json['avatar_url'] as String?,
    coverUrl: json['cover_url'] as String?,
    bio: json['bio'] as String?,
    city: json['city'] as String?,
    workplace: json['workplace'] as String?,
    createdAt: json['created_at'] != null
        ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
        : DateTime.now(),
  );

  @override
  bool operator ==(Object other) => identical(this, other) || other is UserModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 2. Post Table Model (SDD §III.2.4)
class PostModel {
  final String id;
  final String authorId;
  final String? content;
  final List<String> mediaUrls;
  final PostAudience audience;
  final String? sharedPostId;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PostModel({
    required this.id,
    required this.authorId,
    this.content,
    this.mediaUrls = const [],
    this.audience = PostAudience.friends,
    this.sharedPostId,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isEdited => updatedAt.isAfter(createdAt);

  PostModel copyWith({
    String? id,
    String? authorId,
    String? content,
    List<String>? mediaUrls,
    PostAudience? audience,
    String? sharedPostId,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      audience: audience ?? this.audience,
      sharedPostId: sharedPostId ?? this.sharedPostId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'author_id': authorId,
    'content': content,
    'media_urls': mediaUrls,
    'audience': audience.toDbString(),
    'shared_post_id': sharedPostId,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  factory PostModel.fromJson(Map<String, dynamic> json) => PostModel(
    id: json['id'].toString(),
    authorId: (json['author_id'] ?? json['authorId'] ?? '').toString(),
    content: json['content'] as String?,
    mediaUrls: (json['media_urls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
    audience: PostAudience.fromString(json['audience'] as String? ?? 'friends'),
    sharedPostId: json['shared_post_id']?.toString(),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    updatedAt: json['updated_at'] != null
        ? DateTime.parse(json['updated_at'] as String)
        : (json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now()),
  );

  @override
  bool operator ==(Object other) => identical(this, other) || other is PostModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 3. Comment Table Model (SDD §III.2.4)
class CommentModel {
  final String id;
  final String postId;
  final String authorId;
  final String content;
  final DateTime createdAt;

  const CommentModel({
    required this.id,
    required this.postId,
    required this.authorId,
    required this.content,
    required this.createdAt,
  });

  CommentModel copyWith({
    String? id,
    String? postId,
    String? authorId,
    String? content,
    DateTime? createdAt,
  }) {
    return CommentModel(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      content: content ?? this.content,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'author_id': authorId,
    'content': content,
    'created_at': createdAt.toIso8601String(),
  };

  factory CommentModel.fromJson(Map<String, dynamic> json) => CommentModel(
    id: json['id'].toString(),
    postId: json['post_id'].toString(),
    authorId: json['author_id'].toString(),
    content: json['content'] as String,
    createdAt: DateTime.parse(json['created_at'] as String),
  );

  @override
  bool operator ==(Object other) => identical(this, other) || other is CommentModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

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

/// 5. Friendship Table Model (SDD §III.2.4)
class FriendshipModel {
  final String id;
  final String requesterId;
  final String receiverId;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  const FriendshipModel({
    required this.id,
    required this.requesterId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.respondedAt,
  });

  FriendshipModel copyWith({
    String? id,
    String? requesterId,
    String? receiverId,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return FriendshipModel(
      id: id ?? this.id,
      requesterId: requesterId ?? this.requesterId,
      receiverId: receiverId ?? this.receiverId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'requester_id': requesterId,
    'receiver_id': receiverId,
    'status': status.name,
    'created_at': createdAt.toIso8601String(),
    'responded_at': respondedAt?.toIso8601String(),
  };

  factory FriendshipModel.fromJson(Map<String, dynamic> json) => FriendshipModel(
    id: json['id']?.toString() ?? '',
    requesterId: (json['requester_id'] ?? json['requesterId'] ?? '').toString(),
    receiverId: (json['receiver_id'] ?? json['receiverId'] ?? '').toString(),
    status: FriendshipStatus.fromString(json['status'] as String? ?? 'none'),
    createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    respondedAt: json['responded_at'] != null ? DateTime.tryParse(json['responded_at'] as String) : null,
  );

  @override
  bool operator ==(Object other) => identical(this, other) || other is FriendshipModel && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

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

// =============================================================================
// Presentation View Aggregate DTOs
// =============================================================================

/// Aggregated Feed Post with joined Author, Counters, and Current Viewer Reaction State.
class FeedPostView {
  final PostModel post;
  final UserModel author;
  final int reactionCount;
  final Map<ReactionType, int> reactionTypeCounts;
  final ReactionType? currentUserReaction;
  final int commentCount;
  final int shareCount;
  final FeedPostView? sharedPost;
  final bool isOriginalDeleted;

  const FeedPostView({
    required this.post,
    required this.author,
    required this.reactionCount,
    required this.reactionTypeCounts,
    this.currentUserReaction,
    required this.commentCount,
    required this.shareCount,
    this.sharedPost,
    this.isOriginalDeleted = false,
  });

  FeedPostView copyWith({
    PostModel? post,
    UserModel? author,
    int? reactionCount,
    Map<ReactionType, int>? reactionTypeCounts,
    ReactionType? currentUserReaction,
    int? commentCount,
    int? shareCount,
    FeedPostView? sharedPost,
    bool? isOriginalDeleted,
  }) {
    return FeedPostView(
      post: post ?? this.post,
      author: author ?? this.author,
      reactionCount: reactionCount ?? this.reactionCount,
      reactionTypeCounts: reactionTypeCounts ?? this.reactionTypeCounts,
      currentUserReaction: currentUserReaction ?? this.currentUserReaction,
      commentCount: commentCount ?? this.commentCount,
      shareCount: shareCount ?? this.shareCount,
      sharedPost: sharedPost ?? this.sharedPost,
      isOriginalDeleted: isOriginalDeleted ?? this.isOriginalDeleted,
    );
  }

  factory FeedPostView.fromJson(Map<String, dynamic> json) {
    final postData = json['post'] is Map<String, dynamic>
        ? json['post'] as Map<String, dynamic>
        : json;
    final authorData = json['author'] as Map<String, dynamic>? ?? {};
    final reactionTypeCountsRaw = json['reaction_type_counts'] as Map<String, dynamic>? ?? {};
    final reactionTypeCounts = <ReactionType, int>{};
    reactionTypeCountsRaw.forEach((k, v) {
      final rType = ReactionType.fromString(k);
      if (rType != null) {
        reactionTypeCounts[rType] = (v is num) ? v.toInt() : int.tryParse(v.toString()) ?? 0;
      }
    });

    return FeedPostView(
      post: PostModel.fromJson(postData),
      author: UserModel.fromJson(authorData),
      reactionCount: (json['reaction_count'] as num?)?.toInt() ?? 0,
      reactionTypeCounts: reactionTypeCounts,
      currentUserReaction: ReactionType.fromString(
        json['current_user_reaction'] as String? ?? json['user_reaction'] as String?,
      ),
      commentCount: (json['comment_count'] as num?)?.toInt() ?? 0,
      shareCount: (json['share_count'] as num?)?.toInt() ?? 0,
      sharedPost: json['shared_post'] != null && json['shared_post'] is Map<String, dynamic>
          ? FeedPostView.fromJson(json['shared_post'] as Map<String, dynamic>)
          : null,
      isOriginalDeleted: json['is_original_deleted'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'post': post.toJson(),
    'author': author.toJson(),
    'reaction_count': reactionCount,
    'reaction_type_counts': reactionTypeCounts.map((k, v) => MapEntry(k.name, v)),
    'current_user_reaction': currentUserReaction?.name,
    'comment_count': commentCount,
    'share_count': shareCount,
    'shared_post': sharedPost?.toJson(),
    'is_original_deleted': isOriginalDeleted,
  };
}

/// Joined Comment tile with author info.
class CommentView {
  final CommentModel comment;
  final UserModel author;

  const CommentView({
    required this.comment,
    required this.author,
  });

  factory CommentView.fromJson(Map<String, dynamic> json) {
    if (json.containsKey('comment') && json['comment'] is Map<String, dynamic>) {
      return CommentView(
        comment: CommentModel.fromJson(json['comment'] as Map<String, dynamic>),
        author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
      );
    }
    return CommentView(
      comment: CommentModel.fromJson(json),
      author: UserModel.fromJson(json['author'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
    'comment': comment.toJson(),
    'author': author.toJson(),
  };
}

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
