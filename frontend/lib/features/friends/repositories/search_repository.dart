import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:clone_facebook/core/network/api_client.dart';

import '../models/user_result.dart';

abstract interface class SearchRepository {
  Future<SearchResults> search(String query, SearchKind kind, {int page = 1});
}

class ApiSearchRepository implements SearchRepository {
  ApiSearchRepository(this.client);
  final ApiClient client;
  @override
  Future<SearchResults> search(
    String query,
    SearchKind kind, {
    int page = 1,
  }) async {
    final response = await client.get<Map<String, dynamic>>(
      '/search/${kind == SearchKind.people ? 'users' : 'posts'}',
      queryParameters: {'q': query, 'page': page, 'limit': 20},
    );
    final json = response.data!;
    final rows = (json['data'] as List).cast<Map<String, dynamic>>();
    final paging = json['pagination'] as Map<String, dynamic>;
    return SearchResults(
      people: kind == SearchKind.people
          ? rows.map(UserResult.fromJson).toList()
          : const [],
      posts: kind == SearchKind.posts
          ? rows.map(SearchPost.fromJson).toList()
          : const [],
      total: paging['total'] as int,
      page: paging['page'] as int,
      hasMore: paging['has_more'] as bool,
    );
  }
}

final searchRepositoryProvider = Provider<SearchRepository>(
  (ref) => ApiSearchRepository(ref.watch(apiClientProvider)),
);

/// Member 1 can supply the existing Post Detail route without adding a new page here.
final postDetailPathBuilderProvider = Provider<String Function(String)?>(
  (ref) => null,
);
