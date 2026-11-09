import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';
import 'package:clone_facebook/features/auth/models/user.dart';
import 'package:clone_facebook/features/feed/feed_repository.dart';
import 'package:clone_facebook/features/feed/home_feed_screen.dart';
import 'package:clone_facebook/features/feed/models/feed_models.dart';
import 'package:clone_facebook/features/feed/notifications_screen.dart';
import 'package:clone_facebook/features/feed/post_detail_screen.dart';

class SignedInAuth extends AuthStateNotifier {
  @override
  AuthState build() => const AuthState(
    isLoading: false,
    user: User(id: 'alice', email: 'alice@example.test', fullName: 'Alice'),
  );
}

/// Deterministic data only; production screens use ApiFeedRepository.
class FakeFeedRepository implements FeedRepository {
  FeedPost post = FeedPost(
    id: 'p1',
    author: const FeedUser(id: 'bob', name: 'Bob Tran'),
    content: 'Learning Flutter with friends.',
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    likeCount: 2,
    commentCount: 1,
  );
  List<NotificationItem> items = [
    NotificationItem(
      id: 'n1',
      kind: NotificationKind.reaction,
      actor: const FeedUser(id: 'bob', name: 'Bob Tran'),
      createdAt: DateTime.now(),
      isRead: false,
      postId: 'p1',
    ),
  ];
  int likeCalls = 0;
  bool failFeed = false;

  @override
  Future<FeedPage> feed(int page) async {
    if (failFeed) throw Exception('Unable to connect. Please try again.');
    return FeedPage(posts: [post], hasMore: false);
  }

  @override
  Future<FeedPost> getPost(String id) async => post;

  @override
  Future<List<FeedUser>> likes(String postId) async => const [
    FeedUser(id: 'carl', name: 'Carl Le'),
  ];

  @override
  Future<FeedPost> setLike(String postId, bool on) async {
    likeCalls++;
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return post = FeedPost(
      id: post.id,
      author: post.author,
      content: post.content,
      createdAt: post.createdAt,
      likeCount: post.likeCount + (on ? 1 : -1),
      commentCount: post.commentCount,
      likedByMe: on,
      savedByMe: post.savedByMe,
    );
  }

  @override
  Future<FeedPost> setSaved(String postId, bool on) async => post = FeedPost(
    id: post.id,
    author: post.author,
    content: post.content,
    createdAt: post.createdAt,
    likeCount: post.likeCount,
    commentCount: post.commentCount,
    likedByMe: post.likedByMe,
    savedByMe: on,
  );

  @override
  Future<NotificationList> notifications() async => NotificationList(
    items: items,
    unread: items.where((n) => !n.isRead).length,
  );

  @override
  Future<void> markRead(String id) async => items = [
    for (final n in items)
      NotificationItem(
        id: n.id,
        kind: n.kind,
        actor: n.actor,
        createdAt: n.createdAt,
        isRead: n.id == id || n.isRead,
        postId: n.postId,
      ),
  ];

  @override
  Future<void> markAllRead() async {
    for (final n in List.of(items)) {
      await markRead(n.id);
    }
  }
}

Future<void> pump(WidgetTester tester, FakeFeedRepository repo, Widget screen) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(SignedInAuth.new),
        feedRepositoryProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(home: screen),
    ),
  );
}

void main() {
  testWidgets('Home Feed shows posts and a double tap likes only once', (
    tester,
  ) async {
    final repo = FakeFeedRepository();
    await pump(tester, repo, const HomeFeedScreen());
    await tester.pumpAndSettle();
    expect(find.text('Learning Flutter with friends.'), findsOneWidget);
    expect(find.text('Bob Tran'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    final like = find.byTooltip('Like');
    await tester.tap(like);
    await tester.tap(like); // second tap while the first is in flight
    await tester.pumpAndSettle();
    expect(repo.likeCalls, 1);
    expect(find.text('3'), findsOneWidget);
    expect(find.byTooltip('Unlike'), findsOneWidget);
  });

  testWidgets('Home Feed shows the error and recovers on Retry', (
    tester,
  ) async {
    final repo = FakeFeedRepository()..failFeed = true;
    await pump(tester, repo, const HomeFeedScreen());
    await tester.pumpAndSettle();
    expect(find.textContaining('Unable to connect'), findsOneWidget);
    repo.failFeed = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Learning Flutter with friends.'), findsOneWidget);
  });

  testWidgets('Post Detail shows full text and the likes sheet', (
    tester,
  ) async {
    await pump(
      tester,
      FakeFeedRepository(),
      const PostDetailScreen(postId: 'p1'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Learning Flutter with friends.'), findsOneWidget);
    await tester.tap(find.text('2 likes'));
    await tester.pumpAndSettle();
    expect(find.text('Carl Le'), findsOneWidget);
  });

  testWidgets('Notifications list unread items and mark all read', (
    tester,
  ) async {
    await pump(tester, FakeFeedRepository(), const NotificationsScreen());
    await tester.pumpAndSettle();
    expect(find.text('Bob Tran liked your post.'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget);
    await tester.tap(find.text('Mark all read'));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.circle), findsNothing);
  });
}
