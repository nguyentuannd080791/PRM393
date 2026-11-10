import 'dart:collection';
import 'feed_post_view.dart';

/// Paginated posts result encapsulating a list of [FeedPostView] items
/// alongside backend pagination metadata (total, totalPages, page, limit).
class PaginatedPostsResult extends ListBase<FeedPostView> {
  final List<FeedPostView> posts;
  final int total;
  final int totalPages;
  final int page;
  final int limit;

  PaginatedPostsResult({
    required this.posts,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.limit,
  });

  @override
  int get length => posts.length;

  @override
  set length(int newLength) {
    posts.length = newLength;
  }

  @override
  FeedPostView operator [](int index) => posts[index];

  @override
  void operator []=(int index, FeedPostView value) {
    posts[index] = value;
  }

  factory PaginatedPostsResult.fromJson(
    dynamic data, {
    Map<String, dynamic>? paginationJson,
    int defaultPage = 1,
    int defaultLimit = 10,
  }) {
    List<dynamic> list;
    if (data is List<dynamic>) {
      list = data;
    } else if (data is Map<String, dynamic> && data['posts'] is List<dynamic>) {
      list = data['posts'] as List<dynamic>;
    } else {
      list = [];
    }

    final posts = list
        .map((item) => FeedPostView.fromJson(item as Map<String, dynamic>))
        .toList();

    final pagMap = paginationJson ??
        (data is Map<String, dynamic> && data['pagination'] is Map<String, dynamic>
            ? data['pagination'] as Map<String, dynamic>
            : null);

    final total = pagMap != null && pagMap['total'] != null
        ? (pagMap['total'] as num).toInt()
        : posts.length;
    final totalPages = pagMap != null && pagMap['totalPages'] != null
        ? (pagMap['totalPages'] as num).toInt()
        : (total > 0 ? 1 : 0);
    final page = pagMap != null && pagMap['page'] != null
        ? (pagMap['page'] as num).toInt()
        : defaultPage;
    final limit = pagMap != null && pagMap['limit'] != null
        ? (pagMap['limit'] as num).toInt()
        : defaultLimit;

    return PaginatedPostsResult(
      posts: posts,
      total: total,
      totalPages: totalPages,
      page: page,
      limit: limit,
    );
  }

  Map<String, dynamic> toJson() => {
    'posts': posts.map((p) => p.toJson()).toList(),
    'pagination': {
      'total': total,
      'totalPages': totalPages,
      'page': page,
      'limit': limit,
    },
  };
}
