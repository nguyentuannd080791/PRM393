import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/network/api_client.dart';

import 'models/feed_models.dart';

abstract interface class FeedRepository {
  Future<FeedPage> feed(int page);
  Future<FeedPost> getPost(String id);
  Future<List<FeedUser>> likes(String postId);
  Future<FeedPost> setLike(String postId, bool on);
  Future<FeedPost> setSaved(String postId, bool on);
  Future<NotificationList> notifications();
  Future<void> markRead(String id);
  Future<void> markAllRead();
}

class ApiFeedRepository implements FeedRepository {
  ApiFeedRepository(this.client);
  final ApiClient client;
  static const pageSize = 20;

  Future<Map<String, dynamic>> _json(Future<dynamic> request) async =>
      (await request).data as Map<String, dynamic>;

  List<Map<String, dynamic>> _rows(Map<String, dynamic> json) =>
      (json['data'] as List).cast<Map<String, dynamic>>();

  @override
  Future<FeedPage> feed(int page) async {
    final json = await _json(
      client.get<Map<String, dynamic>>(
        '/feed',
        queryParameters: {'page': page, 'limit': pageSize},
      ),
    );
    return FeedPage(
      posts: _rows(json).map(FeedPost.fromJson).toList(),
      hasMore: json['pagination']['has_more'] as bool,
    );
  }

  Future<FeedPost> _post(Future<dynamic> request) async =>
      FeedPost.fromJson((await _json(request))['data'] as Map<String, dynamic>);

  @override
  Future<FeedPost> getPost(String id) =>
      _post(client.get<Map<String, dynamic>>('/feed/posts/$id'));

  @override
  Future<List<FeedUser>> likes(String postId) async {
    final json = await _json(
      client.get<Map<String, dynamic>>(
        '/feed/posts/$postId/likes',
        queryParameters: {'limit': 100},
      ),
    );
    return _rows(json).map(FeedUser.fromJson).toList();
  }

  @override
  Future<FeedPost> setLike(String postId, bool on) => _post(
    on
        ? client.put<Map<String, dynamic>>('/feed/posts/$postId/like')
        : client.delete<Map<String, dynamic>>('/feed/posts/$postId/like'),
  );

  @override
  Future<FeedPost> setSaved(String postId, bool on) => _post(
    on
        ? client.put<Map<String, dynamic>>('/feed/posts/$postId/save')
        : client.delete<Map<String, dynamic>>('/feed/posts/$postId/save'),
  );

  @override
  Future<NotificationList> notifications() async {
    final json = await _json(
      client.get<Map<String, dynamic>>(
        '/notifications',
        queryParameters: {'limit': 50},
      ),
    );
    return NotificationList(
      items: _rows(json).map(NotificationItem.fromJson).toList(),
      unread: json['unread_count'] as int? ?? 0,
    );
  }

  @override
  Future<void> markRead(String id) async {
    await client.patch('/notifications/$id/read');
  }

  @override
  Future<void> markAllRead() async {
    await client.patch('/notifications/read-all');
  }
}

final feedRepositoryProvider = Provider<FeedRepository>(
  (ref) => ApiFeedRepository(ref.watch(apiClientProvider)),
);
