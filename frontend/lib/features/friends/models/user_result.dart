enum SearchKind { people, posts }

class UserResult {
  const UserResult({
    required this.id,
    required this.name,
    this.bio,
    this.relationship = 'none',
    this.requestId,
  });
  final String id;
  final String name;
  final String? bio;
  final String relationship;
  final String? requestId;

  factory UserResult.fromJson(Map<String, dynamic> json) {
    final relation = json['relationship'] as Map<String, dynamic>?;
    return UserResult(
      id: json['id'] as String,
      name: json['full_name'] as String? ?? 'Unknown user',
      bio: json['bio'] as String?,
      relationship: relation?['status'] as String? ?? 'none',
      requestId: relation?['request_id'] as String?,
    );
  }
}

class SearchPost {
  const SearchPost({
    required this.id,
    required this.author,
    required this.content,
    required this.createdAt,
  });
  final String id;
  final UserResult author;
  final String content;
  final DateTime createdAt;

  factory SearchPost.fromJson(Map<String, dynamic> json) => SearchPost(
    id: json['id'] as String,
    author: UserResult.fromJson(json['author'] as Map<String, dynamic>),
    content: json['content'] as String? ?? '',
    createdAt: DateTime.parse(json['created_at'] as String),
  );
}

class SearchResults {
  const SearchResults({
    this.people = const [],
    this.posts = const [],
    this.total = 0,
    this.page = 1,
    this.hasMore = false,
  });
  final List<UserResult> people;
  final List<SearchPost> posts;
  final int total;
  final int page;
  final bool hasMore;

  SearchResults append(SearchResults next) => SearchResults(
    people: [...people, ...next.people],
    posts: [...posts, ...next.posts],
    total: next.total,
    page: next.page,
    hasMore: next.hasMore,
  );
}
