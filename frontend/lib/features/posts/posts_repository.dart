import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/network/api_client.dart';

class ManagedPost {
  const ManagedPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.content,
    required this.createdAt,
    required this.updatedAt,
    required this.audience,
    required this.likes,
    required this.comments,
  });

  final String id;
  final String authorId;
  final String authorName;
  final String content;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String audience;
  final int likes;
  final int comments;

  factory ManagedPost.fromJson(Map<String, dynamic> json) {
    final author = json['author'] as Map<String, dynamic>? ?? const {};
    final createdAt = DateTime.parse(json['created_at'] as String);
    return ManagedPost(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: author['full_name'] as String? ?? 'Unknown user',
      content: json['content'] as String? ?? '',
      createdAt: createdAt,
      updatedAt:
          DateTime.tryParse(json['updated_at'] as String? ?? '') ?? createdAt,
      audience: json['audience'] as String? ?? 'public',
      likes: json['likes'] as int? ?? 0,
      comments: json['comments'] as int? ?? 0,
    );
  }
}

abstract interface class PostsRepository {
  Future<List<ManagedPost>> getUserPosts(String userId);
  Future<void> createPost(String content, {String audience = 'public'});
  Future<void> updatePost(String postId, String content);
  Future<void> deletePost(String postId);
  Future<Map<String, dynamic>> getInsights(String postId);
}

class ApiPostsRepository implements PostsRepository {
  ApiPostsRepository(this.client);
  final ApiClient client;

  @override
  Future<List<ManagedPost>> getUserPosts(String userId) async {
    final rows = <ManagedPost>[];
    var page = 1;
    while (true) {
      final response = await client.get<Map<String, dynamic>>(
        '/posts/users/$userId',
        queryParameters: {'page': page, 'limit': 100},
      );
      final json = response.data!;
      final data = (json['data'] as List).cast<Map<String, dynamic>>();
      rows.addAll(data.map(ManagedPost.fromJson));
      final paging = json['pagination'] as Map<String, dynamic>;
      if (paging['has_more'] != true) return rows;
      page++;
    }
  }

  @override
  Future<void> createPost(String content, {String audience = 'public'}) async {
    await client.post(
      '/posts',
      data: {'content': content, 'audience': audience},
    );
  }

  @override
  Future<void> updatePost(String postId, String content) async {
    await client.put('/posts/$postId', data: {'content': content});
  }

  @override
  Future<void> deletePost(String postId) async {
    await client.delete('/posts/$postId');
  }

  @override
  Future<Map<String, dynamic>> getInsights(String postId) async {
    final response = await client.get<Map<String, dynamic>>(
      '/posts/$postId/insights',
    );
    return response.data!['data'] as Map<String, dynamic>;
  }
}

final postsRepositoryProvider = Provider<PostsRepository>(
  (ref) => ApiPostsRepository(ref.watch(apiClientProvider)),
);
