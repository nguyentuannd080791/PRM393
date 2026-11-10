import 'comment_model.dart';
import 'user_model.dart';

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
