import '../enums/app_enums.dart';

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
