import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/network/api_client.dart';
import 'package:clone_facebook/features/feed/models/feed_models.dart';

class PostComment {
  const PostComment({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
    required this.isMine,
  });
  final String id;
  final FeedUser author;
  final String content;
  final DateTime createdAt;
  final bool isMine;

  factory PostComment.fromJson(Map<String, dynamic> json) => PostComment(
    id: json['id'] as String,
    author: FeedUser.fromJson(json['author'] as Map<String, dynamic>),
    content: json['content'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
    isMine: json['is_mine'] as bool? ?? false,
  );
}

abstract interface class InteractionsRepository {
  Future<List<PostComment>> comments(String postId);
  Future<PostComment> addComment(String postId, String content);
  Future<void> deleteComment(String commentId);
  Future<List<FeedPost>> likedPosts();
  Future<List<FeedPost>> savedPosts();
}

class ApiInteractionsRepository implements InteractionsRepository {
  ApiInteractionsRepository(this.client);
  final ApiClient client;

  // Each response is bounded (100 rows); follow the pages so nothing is hidden.
  Future<List<Map<String, dynamic>>> _rows(String path) async {
    final rows = <Map<String, dynamic>>[];
    for (var page = 1; page <= 100; page++) {
      final response = await client.get<Map<String, dynamic>>(
        path,
        queryParameters: {'page': page, 'limit': 100},
      );
      final json = response.data!;
      rows.addAll((json['data'] as List).cast<Map<String, dynamic>>());
      if (json['pagination']?['has_more'] != true) break;
    }
    return rows;
  }

  @override
  Future<List<PostComment>> comments(String postId) async =>
      (await _rows('/posts/$postId/comments')).map(PostComment.fromJson).toList();

  @override
  Future<PostComment> addComment(String postId, String content) async {
    final response = await client.post<Map<String, dynamic>>(
      '/posts/$postId/comments',
      data: {'content': content},
    );
    return PostComment.fromJson(response.data!['data'] as Map<String, dynamic>);
  }

  @override
  Future<void> deleteComment(String commentId) async {
    await client.delete('/comments/$commentId');
  }

  @override
  Future<List<FeedPost>> likedPosts() async =>
      (await _rows('/me/liked-posts')).map(FeedPost.fromJson).toList();

  @override
  Future<List<FeedPost>> savedPosts() async =>
      (await _rows('/me/saved-posts')).map(FeedPost.fromJson).toList();
}

final interactionsRepositoryProvider = Provider<InteractionsRepository>(
  (ref) => ApiInteractionsRepository(ref.watch(apiClientProvider)),
);
