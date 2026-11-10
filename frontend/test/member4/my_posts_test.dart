import 'package:clone_facebook/app/app_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';
import 'package:clone_facebook/features/auth/models/user.dart';
import 'package:clone_facebook/features/posts/my_posts_screen.dart';
import 'package:clone_facebook/features/posts/post_editor_screen.dart';
import 'package:clone_facebook/features/posts/post_insights_screen.dart';
import 'package:clone_facebook/features/posts/posts_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _SignedInAuth extends AuthStateNotifier {
  @override
  AuthState build() => const AuthState(
    isLoading: false,
    user: User(id: 'alice', email: 'alice@example.test', fullName: 'Alice'),
  );
}

class _FakePostsRepository implements PostsRepository {
  final List<ManagedPost> posts = [
    ManagedPost(
      id: 'post-1',
      authorId: 'alice',
      authorName: 'Alice Nguyen',
      content: 'A real post from the test repository.',
      createdAt: DateTime(2026, 11, 10, 9),
      updatedAt: DateTime(2026, 11, 10, 9),
      audience: 'public',
      likes: 12,
      comments: 4,
    ),
    ManagedPost(
      id: 'post-2',
      authorId: 'alice',
      authorName: 'Alice Nguyen',
      content: 'A post shared with friends.',
      createdAt: DateTime(2026, 11, 10, 8),
      updatedAt: DateTime(2026, 11, 10, 8),
      audience: 'friends',
      likes: 2,
      comments: 1,
    ),
    ManagedPost(
      id: 'post-3',
      authorId: 'alice',
      authorName: 'Alice Nguyen',
      content: 'A private post just for me.',
      createdAt: DateTime(2026, 11, 10, 7),
      updatedAt: DateTime(2026, 11, 10, 7),
      audience: 'only_me',
      likes: 0,
      comments: 0,
    ),
  ];

  @override
  Future<List<ManagedPost>> getUserPosts(String userId) async => posts
      .map(
        (post) => ManagedPost(
          id: post.id,
          authorId: userId,
          authorName: userId == 'bob' ? 'Bob' : post.authorName,
          content: post.content,
          createdAt: post.createdAt,
          updatedAt: post.updatedAt,
          audience: post.audience,
          likes: post.likes,
          comments: post.comments,
        ),
      )
      .toList();

  @override
  Future<void> createPost(String content, {String audience = 'public'}) async {
    posts.insert(
      0,
      ManagedPost(
        id: 'new-post',
        authorId: 'alice',
        authorName: 'Alice Nguyen',
        content: content,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        audience: audience,
        likes: 0,
        comments: 0,
      ),
    );
  }

  @override
  Future<void> updatePost(String postId, String content) async {
    final index = posts.indexWhere((post) => post.id == postId);
    final post = posts[index];
    posts[index] = ManagedPost(
      id: post.id,
      authorId: post.authorId,
      authorName: post.authorName,
      content: content,
      createdAt: post.createdAt,
      updatedAt: DateTime.now(),
      audience: post.audience,
      likes: post.likes,
      comments: post.comments,
    );
  }

  @override
  Future<void> deletePost(String postId) async {
    posts.removeWhere((post) => post.id == postId);
  }

  @override
  Future<Map<String, dynamic>> getInsights(String postId) async => {
    'post_id': postId,
    'author': {'id': 'alice', 'full_name': 'Alice Nguyen'},
    'content': 'A real post from the test repository.',
    'created_at': DateTime(2026, 11, 10, 9).toIso8601String(),
    'likes': 12,
    'comments': 4,
    'engagement': 16,
    'recent_activity': [
      {
        'actor_name': 'Minh Le',
        'action': 'commented',
        'created_at': DateTime(2026, 11, 10, 9, 20).toIso8601String(),
      },
    ],
  };
}

Future<void> _pumpPosts(
  WidgetTester tester, {
  required String userId,
  required String name,
  required _FakePostsRepository repository,
}) async {
  final router = GoRouter(
    initialLocation: '/posts/$userId',
    routes: [
      GoRoute(
        path: '/posts/:userId',
        builder: (context, state) => MyPostsScreen(
          userId: state.pathParameters['userId']!,
          displayName: name,
        ),
      ),
      GoRoute(
        path: '/post/create',
        builder: (context, state) => const CreatePostPage(),
      ),
      GoRoute(
        path: '/post/:id/insights',
        name: AppRouteNames.postInsights,
        builder: (context, state) =>
            PostInsightsScreen(postId: state.pathParameters['id']!),
      ),
    ],
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_SignedInAuth.new),
        postsRepositoryProvider.overrideWithValue(repository),
      ],
      child: MaterialApp.router(routerConfig: router),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('application router resolves the named post insights route', (
    tester,
  ) async {
    final repository = _FakePostsRepository();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(_SignedInAuth.new),
        postsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(appRouterProvider);
    addTearDown(router.dispose);
    router.go(AppRoutePaths.myPostsPath('alice'));

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();

    expect(find.text('Post Insights'), findsOneWidget);
    expect(
      find.textContaining('A real post from the test repository.'),
      findsOneWidget,
    );
  });

  testWidgets('owner can view insights, edit and delete an API-backed post', (
    tester,
  ) async {
    final repository = _FakePostsRepository();
    await _pumpPosts(
      tester,
      userId: 'alice',
      name: 'Alice Nguyen',
      repository: repository,
    );

    expect(find.text('My Posts'), findsOneWidget);
    expect(find.text('12 Likes'), findsOneWidget);
    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(find.text('Post Insights'), findsOneWidget);
    expect(find.text('12'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Minh Le commented on your post'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).last,
      'Edited post from the owner.',
    );
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Edited post from the owner.'), findsOneWidget);

    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();
    expect(find.text('No public posts yet.'), findsOneWidget);
  });

  testWidgets('New Post opens full composer and publishes through repository', (
    tester,
  ) async {
    final repository = _FakePostsRepository();
    await _pumpPosts(
      tester,
      userId: 'alice',
      name: 'Alice Nguyen',
      repository: repository,
    );

    await tester.tap(find.text('New Post'));
    await tester.pumpAndSettle();
    expect(find.text('Create Post'), findsOneWidget);
    expect(find.text('Posting to your profile stream'), findsOneWidget);
    expect(find.text('0 / 5000'), findsOneWidget);
    await tester.enterText(
      find.byType(TextField),
      'A new post from the full composer.',
    );
    await tester.tap(find.text('Publish Post'));
    await tester.pumpAndSettle();
    expect(find.text('A new post from the full composer.'), findsOneWidget);
  });

  testWidgets('Create Post allows up to 5000 characters', (tester) async {
    await _pumpPosts(
      tester,
      userId: 'alice',
      name: 'Alice Nguyen',
      repository: _FakePostsRepository(),
    );
    await tester.tap(find.text('New Post'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byType(TextField),
      List.filled(5001, 'a').join(),
    );
    await tester.pump();

    expect(find.text('5000 / 5000'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).last).controller!.text,
      hasLength(5000),
    );
  });

  testWidgets('another user can view posts but does not get owner actions', (
    tester,
  ) async {
    await _pumpPosts(
      tester,
      userId: 'bob',
      name: 'Bob',
      repository: _FakePostsRepository(),
    );

    expect(find.text('Bob’s Posts'), findsOneWidget);
    expect(find.text('A real post from the test repository.'), findsOneWidget);
    expect(find.text('Insights'), findsNothing);
    expect(find.text('Edit'), findsNothing);
    expect(find.text('Delete'), findsNothing);
    expect(find.text('New Post'), findsNothing);
  });

  testWidgets(
    'My Posts search filters the displayed posts and can be cleared',
    (tester) async {
      await _pumpPosts(
        tester,
        userId: 'alice',
        name: 'Alice Nguyen',
        repository: _FakePostsRepository(),
      );

      await tester.enterText(find.byType(TextField), 'real post');
      await tester.pumpAndSettle();
      expect(
        find.text('A real post from the test repository.'),
        findsOneWidget,
      );

      await tester.enterText(find.byType(TextField), 'not found');
      await tester.pumpAndSettle();
      expect(find.text('No posts match “not found”.'), findsOneWidget);

      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(
        find.text('A real post from the test repository.'),
        findsOneWidget,
      );
    },
  );

  testWidgets('audience tabs filter public, friends, and private posts', (
    tester,
  ) async {
    await _pumpPosts(
      tester,
      userId: 'alice',
      name: 'Alice Nguyen',
      repository: _FakePostsRepository(),
    );

    expect(find.text('A real post from the test repository.'), findsOneWidget);
    expect(find.text('A post shared with friends.'), findsNothing);
    expect(find.text('A private post just for me.'), findsNothing);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    expect(find.text('A post shared with friends.'), findsOneWidget);
    expect(find.text('A real post from the test repository.'), findsNothing);

    await tester.tap(find.text('Only me'));
    await tester.pumpAndSettle();
    expect(find.text('A private post just for me.'), findsOneWidget);
    expect(find.text('A post shared with friends.'), findsNothing);

    await tester.tap(find.text('Public'));
    await tester.pumpAndSettle();
    expect(find.text('A real post from the test repository.'), findsOneWidget);
    expect(find.text('A private post just for me.'), findsNothing);
  });
}
