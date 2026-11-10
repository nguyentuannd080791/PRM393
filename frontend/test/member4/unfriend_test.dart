import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clone_facebook/core/enums/app_enums.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';
import 'package:clone_facebook/features/auth/models/user.dart';
import 'package:clone_facebook/features/friends/models/friend_request.dart';
import 'package:clone_facebook/features/friends/models/user_result.dart';
import 'package:clone_facebook/features/friends/repositories/friends_repository.dart';
import 'package:clone_facebook/features/friends/repositories/search_repository.dart';
import 'package:clone_facebook/features/profile/presentation/widgets/profile_action_button.dart';

class SignedInAuth extends AuthStateNotifier {
  @override
  AuthState build() => const AuthState(
    isLoading: false,
    user: User(id: 'alice', email: '', fullName: 'Alice'),
  );
}

class FakeFriends implements FriendsRepository, SearchRepository {
  final removed = <String>[];
  bool fail = false;

  @override
  Future<void> removeFriend(String userId) async {
    if (fail) throw Exception('Unable to connect. Please try again.');
    removed.add(userId);
  }

  @override
  Future<List<FriendRequest>> connections(String kind) async => const [];
  @override
  Future<void> sendRequest(String receiverId) async {}
  @override
  Future<void> changeRequest(String requestId, String action) async {}
  @override
  Future<SearchResults> search(String query, SearchKind kind, {int page = 1}) async =>
      const SearchResults(total: 0);
}

Future<void> pumpButton(WidgetTester tester, FakeFriends fake) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(SignedInAuth.new),
        sessionUserIdProvider.overrideWithValue('alice'),
        friendsRepositoryProvider.overrideWithValue(fake),
        searchRepositoryProvider.overrideWithValue(fake),
      ],
      child: const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ProfileActionButton(
              userId: 'bob',
              status: UserRelationshipStatus.friends,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> openUnfriendDialog(WidgetTester tester) async {
  await tester.tap(find.byKey(const Key('profile_friends_menu_button')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Unfriend'));
  await tester.pumpAndSettle();
  expect(find.text('Remove this person from your friends?'), findsOneWidget);
}

void main() {
  testWidgets('Unfriend asks for confirmation and Cancel changes nothing', (tester) async {
    final fake = FakeFriends();
    await pumpButton(tester, fake);
    expect(find.text('Friends'), findsOneWidget);
    await openUnfriendDialog(tester);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(fake.removed, isEmpty);
  });

  testWidgets('Confirming Unfriend calls the API once for that user', (tester) async {
    final fake = FakeFriends();
    await pumpButton(tester, fake);
    await openUnfriendDialog(tester);
    await tester.tap(find.byKey(const Key('confirm_unfriend_button')));
    await tester.pumpAndSettle();
    expect(fake.removed, ['bob']);
    expect(find.text('Friend removed.'), findsOneWidget);
  });

  testWidgets('A failed Unfriend shows the error instead of a false success', (tester) async {
    final fake = FakeFriends()..fail = true;
    await pumpButton(tester, fake);
    await openUnfriendDialog(tester);
    await tester.tap(find.byKey(const Key('confirm_unfriend_button')));
    await tester.pumpAndSettle();
    expect(fake.removed, isEmpty);
    expect(find.textContaining('Unable to connect'), findsOneWidget);
    expect(find.text('Friend removed.'), findsNothing);
  });
}
