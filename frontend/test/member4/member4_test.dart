import 'package:clone_facebook/features/friends/repositories/friends_repository.dart';
import 'package:clone_facebook/features/friends/providers/friends_provider.dart';
import 'package:clone_facebook/features/friends/models/friend_request.dart';

import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clone_facebook/app/app_router.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/features/auth/models/user.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';
import 'package:clone_facebook/features/friends/repositories/search_repository.dart';
import 'package:clone_facebook/features/friends/models/user_result.dart';
import 'package:clone_facebook/features/friends/providers/search_provider.dart';

final now = DateTime(2026, 11, 10, 10);
FriendRequest connection(String id, String name) => FriendRequest(
  id: id,
  user: UserResult(id: id, name: name),
  createdAt: now,
  acceptedAt: now,
);

class SignedInAuth extends AuthStateNotifier {
  @override
  AuthState build() => const AuthState(
    isLoading: false,
    user: User(id: 'alice', email: 'alice@example.test', fullName: 'Alice'),
  );
}

/// Deterministic test data only; production screens always use ApiMember4Repository.
class FakeRepository implements SearchRepository, FriendsRepository {
  int sends = 0;
  int searches = 0;
  String relationship = 'none';
  Future<SearchResults> Function(String)? searchHandler;
  Completer<void>? sendGate;
  final friends = [
    connection('minh-le', 'Minh Le'),
    connection('tien', 'Tien Nguyen'),
  ];
  final received = [
    connection('received-1', 'Ha Pham'),
    connection('received-2', 'Nhi Tran'),
  ];
  final sent = [connection('sent-1', 'Quang Le')];

  @override
  Future<SearchResults> search(
    String query,
    SearchKind kind, {
    int page = 1,
  }) async {
    searches++;
    if (searchHandler != null) return searchHandler!(query);
    if (kind == SearchKind.posts) {
      return SearchResults(
        total: 1,
        posts: [
          SearchPost(
            id: 'post',
            author: const UserResult(id: 'bob', name: 'Minh Pham'),
            content: 'Learning Flutter with friends.',
            createdAt: now,
          ),
        ],
      );
    }
    final people =
        [
              const UserResult(
                id: 'minh-le',
                name: 'Minh Le',
                relationship: 'friends',
              ),
              UserResult(
                id: 'bob',
                name: 'Minh Pham',
                relationship: relationship,
              ),
              const UserResult(
                id: 'minh-tran',
                name: 'Minh Tran',
                relationship: 'pending_sent',
              ),
            ]
            .where(
              (user) => user.name.toLowerCase().contains(query.toLowerCase()),
            )
            .toList();
    return SearchResults(total: people.length, people: people);
  }

  @override
  Future<List<FriendRequest>> connections(String kind) async => List.of(
    kind == 'friends'
        ? friends
        : kind == 'received'
        ? received
        : sent,
  );

  @override
  Future<void> sendRequest(String receiverId) async {
    sends++;
    if (sendGate != null) await sendGate!.future;
    relationship = 'pending_sent';
  }

  @override
  Future<void> changeRequest(String id, String action) async {
    final found = [
      ...received,
      ...sent,
    ].firstWhere((request) => request.id == id);
    received.removeWhere((request) => request.id == id);
    sent.removeWhere((request) => request.id == id);
    if (action == 'accept') friends.add(found);
  }
}

ProviderContainer makeContainer(FakeRepository repository) => ProviderContainer(
  overrides: [
    authStateProvider.overrideWith(SignedInAuth.new),
    sessionUserIdProvider.overrideWithValue('alice'),
    searchRepositoryProvider.overrideWithValue(repository),
    friendsRepositoryProvider.overrideWithValue(repository),
  ],
);

Future<GlobalKey> mount(
  WidgetTester tester,
  ProviderContainer container,
  String location,
) async {
  await tester.binding.setSurfaceSize(const Size(390, 844));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey();
  final router = container.read(appRouterProvider);
  addTearDown(router.dispose);
  router.go(location);
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: RepaintBoundary(
        key: key,
        child: MaterialApp.router(
          debugShowCheckedModeBanner: false,
          routerConfig: router,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

Future<void> screenshot(WidgetTester tester, GlobalKey key, String name) async {
  await tester.runAsync(() async {
    final directory = Platform.environment['MEMBER4_SCREENSHOTS'];
    if (directory == null) return;
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    await Directory(directory).create(recursive: true);
    await File('$directory/$name.png')
        .writeAsBytes(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  setUpAll(() async {
    final fonts = Platform.environment['MEMBER4_FONT_DIR'];
    if (fonts == null) return;
    for (final entry in {
      'Roboto': 'roboto-regular.ttf',
      'MaterialIcons': 'materialicons-regular.otf',
    }.entries) {
      final bytes = await File('$fonts/${entry.value}').readAsBytes();
      await (FontLoader(
        entry.key,
      )..addFont(Future.value(ByteData.sublistView(bytes)))).load();
    }
  });
  testWidgets(
    'debounce and generation guard discard outdated search responses',
    (tester) async {
      final repo = FakeRepository();
      final old = Completer<SearchResults>();
      final latest = Completer<SearchResults>();
      repo.searchHandler = (q) => q == 'old' ? old.future : latest.future;
      final container = makeContainer(repo);
      addTearDown(container.dispose);
      final controller = container.read(member4SearchProvider.notifier);
      controller.setQuery('o');
      controller.setQuery('ol');
      controller.setQuery('old');
      await tester.pump(const Duration(milliseconds: 351));
      expect(repo.searches, 1);
      controller.setQuery('new');
      await tester.pump(const Duration(milliseconds: 351));
      latest.complete(
        const SearchResults(
          total: 1,
          people: [UserResult(id: 'new', name: 'New User')],
        ),
      );
      await tester.pump();
      old.complete(
        const SearchResults(
          total: 1,
          people: [UserResult(id: 'old', name: 'Old User')],
        ),
      );
      await tester.pump();
      expect(
        container
            .read(member4SearchProvider)
            .results
            .requireValue
            .people
            .single
            .id,
        'new',
      );
      controller.setQuery('');
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        container.read(member4SearchProvider).results.requireValue.total,
        0,
      );
      expect(repo.searches, 2);
    },
  );

  testWidgets(
    'Search integrates People/Posts, clear, real action state and four-tab navigation',
    (tester) async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);
      final key = await mount(tester, container, AppRoutePaths.search);
      await tester.enterText(find.byType(TextField), 'Minh');
      await tester.pump(const Duration(milliseconds: 351));
      await tester.pumpAndSettle();
      expect(find.text('Minh Pham'), findsOneWidget);
      expect(find.text('Add Friend'), findsOneWidget);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await screenshot(tester, key, 'search');
      await tester.tap(find.text('Add Friend'));
      await tester.pumpAndSettle();
      expect(repo.sends, 1);
      expect(find.text('Request Sent'), findsNWidgets(2));
      await tester.tap(find.text('Posts'));
      await tester.pump(const Duration(milliseconds: 351));
      await tester.pumpAndSettle();
      expect(find.text('Learning Flutter with friends.'), findsOneWidget);
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pumpAndSettle();
      expect(find.text('Learning Flutter with friends.'), findsNothing);
    },
  );

  testWidgets('double submission is blocked until request completes', (
    tester,
  ) async {
    final repo = FakeRepository()..sendGate = Completer<void>();
    final container = makeContainer(repo);
    addTearDown(container.dispose);
    final controller = container.read(friendshipActionsProvider.notifier);
    final first = controller.send('bob');
    await controller.send('bob');
    expect(repo.sends, 1);
    expect(container.read(friendshipActionsProvider), contains('user:bob'));
    repo.sendGate!.complete();
    await first;
    expect(container.read(friendshipActionsProvider), isEmpty);
  });

  testWidgets(
    'Received accept/decline and Sent cancel update pending lists and friends',
    (tester) async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);
      final key = await mount(tester, container, AppRoutePaths.friendRequests);
      expect(find.text('Ha Pham'), findsOneWidget);
      await screenshot(tester, key, 'requests_received');
      await tester.tap(find.text('Accept').first);
      await tester.pumpAndSettle();
      expect(find.text('Ha Pham'), findsNothing);
      expect(
        (await container.read(friendsProvider.future))
            .any((r) => r.user.name == 'Ha Pham'),
        isTrue,
      );
      await tester.tap(find.text('Decline').first);
      await tester.pumpAndSettle();
      expect(find.text('Nhi Tran'), findsNothing);
      await tester.tap(find.textContaining('Sent  '));
      await tester.pumpAndSettle();
      expect(find.text('Quang Le'), findsOneWidget);
      await screenshot(tester, key, 'requests_sent');
      await tester.tap(find.text('Cancel Request'));
      await tester.pumpAndSettle();
      expect(find.text('Quang Le'), findsNothing);
      expect(find.text('No pending sent requests.'), findsOneWidget);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'Friends shows actual count, filters locally, and has a requests shortcut',
    (tester) async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);
      final key = await mount(tester, container, AppRoutePaths.friends);
      expect(find.text('2 Friends'), findsOneWidget);
      expect(find.text('Minh Le'), findsOneWidget);
      await screenshot(tester, key, 'friends');
      await tester.enterText(find.byType(TextField), 'MINH');
      await tester.pumpAndSettle();
      expect(find.text('Minh Le'), findsOneWidget);
      expect(find.text('Tien Nguyen'), findsNothing);
      await tester.tap(find.text('Requests  2'));
      await tester.pumpAndSettle();
      expect(find.text('Friend Requests'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      container.dispose();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'search exposes loading, failure, retry and empty-result states',
    (tester) async {
      final repo = FakeRepository()
        ..searchHandler = (_) =>
            Future.error(StateError('Connection unavailable'));
      final container = makeContainer(repo);
      addTearDown(container.dispose);
      await mount(tester, container, AppRoutePaths.search);
      await tester.enterText(find.byType(TextField), 'missing');
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 351));
      await tester.pumpAndSettle();
      expect(find.textContaining('Connection unavailable'), findsOneWidget);
      repo.searchHandler = (_) async => const SearchResults();
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(
        find.text('No results found. Try another keyword.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'poll refresh picks up accepted friendships from another device',
    (tester) async {
      final repo = FakeRepository();
      final container = makeContainer(repo);
      addTearDown(container.dispose);
      final subscription = container.listen(friendsProvider, (_, _) {});
      await tester.pump();
      expect((await container.read(friendsProvider.future)).length, 2);
      repo.friends.add(connection('remote-friend', 'Remote Friend'));
      await tester.pump(const Duration(seconds: 16));
      await tester.pump();
      expect((await container.read(friendsProvider.future)).length, 3);
      subscription.close();
      container.dispose();
    },
  );

  testWidgets('authenticated identity change clears previous search state', (
    tester,
  ) async {
    final repo = FakeRepository();
    final container = ProviderContainer(
      overrides: [
        authStateProvider.overrideWith(SignedInAuth.new),
        searchRepositoryProvider.overrideWithValue(repo),
        friendsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);
    final subscription = container.listen(member4SearchProvider, (_, _) {});
    container.read(member4SearchProvider.notifier).setQuery('Minh');
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pump();
    expect(container.read(member4SearchProvider).query, 'Minh');
    container.read(authStateProvider.notifier).setUser(null);
    await tester.pump();
    expect(container.read(member4SearchProvider).query, isEmpty);
    expect(container.read(member4SearchProvider).results.requireValue.total, 0);
    subscription.close();
    container.dispose();
    await tester.pump();
  });

  testWidgets('small phone and long identity do not overflow', (tester) async {
    final repo = FakeRepository();
    final container = makeContainer(repo);
    addTearDown(container.dispose);
    await mount(tester, container, AppRoutePaths.search);
    await tester.binding.setSurfaceSize(const Size(320, 700));
    await tester.enterText(find.byType(TextField), 'Minh');
    await tester.pump(const Duration(milliseconds: 351));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
