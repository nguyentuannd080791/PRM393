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
