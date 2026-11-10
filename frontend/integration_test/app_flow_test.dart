// End-to-end run of the real app against a real backend (no mocks).
// Needs: backend on :5000 with users Bob (0900000002) and Dan (0900000003) who each have a post.
//   flutter test integration_test/app_flow_test.dart -d <android-emulator-id>
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:clone_facebook/app/app.dart';
import 'package:clone_facebook/app/route_names.dart';
import 'package:clone_facebook/core/storage/preferences_provider.dart';
import 'package:clone_facebook/features/feed/feed_provider.dart';
import 'package:clone_facebook/features/friends/repositories/search_repository.dart';

/// Another user acting through the real API (a second phone).
Future<Map<String, dynamic>> callApi(
  String method,
  String path, {
  String? token,
  Object? body,
}) async {
  final client = HttpClient();
  final req = await client.openUrl(
    method,
    Uri.parse('http://10.0.2.2:5000/api$path'),
  );
  req.headers.contentType = ContentType.json;
  if (token != null) req.headers.set('Authorization', 'Bearer $token');
  if (body != null) req.write(jsonEncode(body));
  final res = await req.close();
  final json = jsonDecode(
    await res.transform(utf8.decoder).join(),
  ) as Map<String, dynamic>;
  client.close();
  return json;
}

Future<void> settle(WidgetTester t, [int seconds = 2]) async {
  await t.pump(Duration(seconds: seconds));
  await t.pumpAndSettle(
    const Duration(milliseconds: 100),
    EnginePhase.sendSemanticsUpdate,
    const Duration(seconds: 10),
  );
}

Future<void> typeInto(WidgetTester t, Finder f, String text) async {
  await t.ensureVisible(f);
  await t.enterText(f, text);
  await t.pump();
}

Future<void> tapText(WidgetTester t, String text, {int seconds = 2}) async {
  final f = find.text(text).first;
  await t.ensureVisible(f);
  await t.tap(f);
  await settle(t, seconds);
}

Future<void> tapTextContaining(
  WidgetTester t,
  String text, {
  int seconds = 2,
}) async {
  final f = find.textContaining(text).first;
  await t.ensureVisible(f);
  await t.tap(f);
  await settle(t, seconds);
}

Future<void> tapKey(WidgetTester t, String key, {int seconds = 2}) async {
  final f = find.byKey(Key(key));
  await t.ensureVisible(f);
  await t.tap(f);
  await settle(t, seconds);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final stamp = DateTime.now().millisecondsSinceEpoch % 100000000;
  final phone = '09${stamp.toString().padLeft(8, '0')}';

  testWidgets('register, feed, comments, posts, friends, profile, settings', (
    t,
  ) async {
    SharedPreferences.setMockInitialValues(
      {},
    ); // empty device storage = fresh install
    final prefs = await SharedPreferences.getInstance();
    await t.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          commentsPathBuilderProvider.overrideWithValue(
            AppRoutePaths.commentsPath,
          ),
          postDetailPathBuilderProvider.overrideWithValue(
            AppRoutePaths.postDetailPath,
          ),
        ],
        child: const FbCloneApp(),
      ),
    );
    await settle(t, 3);

    // --- SCR16 Login shows phone; SCR17 Register ---
    expect(find.text('Phone Number'), findsOneWidget);
    expect(find.textContaining('Demo'), findsNothing);
    await tapKey(t, 'loginRegisterButton');
    await tapKey(t, 'registerSubmitButton', seconds: 1);
    expect(find.text('Please enter the required information.'), findsWidgets);
    await typeInto(
      t,
      find.byKey(const Key('registerFullNameField')),
      'Carol Vu',
    );
    await typeInto(t, find.byKey(const Key('registerPhoneField')), phone);
    await typeInto(
      t,
      find.byKey(const Key('registerPasswordField')),
      'abcd1234',
    );
    await typeInto(
      t,
      find.byKey(const Key('registerConfirmPasswordField')),
      'abcd1234',
    );
    await tapKey(t, 'registerSubmitButton', seconds: 4);

    // --- SCR01 Home Feed: real posts from other users ---
    expect(find.text('Hello from Bob - first post!'), findsOneWidget);
    expect(find.text('Dan here: Flutter is fun'), findsOneWidget);
    // --- SCR01/SCR02: like + save, post detail with likes sheet ---
    await t.tap(find.text('Like').first);
    await settle(t);
    expect(find.text('Liked'), findsOneWidget);
    await t.tap(find.text('Save').first);
    await settle(t);
    expect(find.text('Saved'), findsOneWidget);
    await t.tap(find.text('Dan here: Flutter is fun'));
    await settle(t);
    expect(find.textContaining(' Like'), findsWidgets);
    await t.tap(find.textContaining(' Like').first);
    await settle(t);
    expect(find.text('Liked by'), findsOneWidget);
    await t.tap(find.byTooltip('Close'));
    await settle(t);
    await t.pageBack();
    await settle(t);

    // --- SCR07 Comments: empty send rejected, add, delete ---
    await t.tap(find.text('Comment').first);
    await settle(t);
    expect(find.text('Comments'), findsOneWidget);
    await t.tap(find.byTooltip('Send'));
    await settle(t, 1);
    expect(find.text('Please enter the required information.'), findsOneWidget);
    await typeInto(t, find.byType(TextField), 'Nice post Dan!');
    await t.tap(find.byTooltip('Send'));
    await settle(t, 4);
    // The delete icon exists only on the list row of my own comment (not in the input field).
    expect(find.byTooltip('Delete comment'), findsOneWidget);
    await t.tap(find.byTooltip('Delete comment'));
    await settle(t, 1);
    await t.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(t);
    expect(find.text('Nice post Dan!'), findsNothing);
    await typeInto(t, find.byType(TextField), 'Kept comment');
    await t.tap(find.byTooltip('Send'));
    await settle(t);
    await t.pageBack();
    await settle(t);
    expect(find.textContaining(' Comment'), findsWidgets);

    // --- SCR04 Post Editor: create ---
    await tapText(t, "What's on your mind?");
    expect(find.text('Create Post'), findsOneWidget);
    await typeInto(t, find.byType(TextField), 'My first post from Carol');
    await tapText(t, 'Publish Post', seconds: 3);
    expect(find.text('My first post from Carol'), findsOneWidget);

    // --- SCR13 Profile, SCR05 My Posts, SCR04 edit, SCR06 insights, delete ---
    await tapText(t, 'Profile');
    expect(find.text('Carol Vu'), findsOneWidget);
    await tapText(t, 'My Posts');
    expect(find.text('My first post from Carol'), findsOneWidget);
    await tapText(t, 'Edit');
    expect(find.text('Edit Post'), findsOneWidget);
    expect(find.text('My first post from Carol'), findsOneWidget);
    await typeInto(t, find.byType(TextField), 'Edited by Carol');
    await tapText(t, 'Save Changes', seconds: 3);
    expect(find.text('Edited by Carol'), findsOneWidget);
    await tapText(t, 'Insights');
    expect(find.textContaining('Likes'), findsWidgets);
    await t.pageBack();
    await settle(t);
    await tapText(t, 'Delete');
    await t.tap(find.widgetWithText(FilledButton, 'Delete'));
    await settle(t, 3);
    expect(find.text('Edited by Carol'), findsNothing);
    await t.pageBack();
    await settle(t);

    // --- SCR08 Liked, SCR09 Saved ---
    await tapText(t, 'Liked Posts');
    expect(find.text('Dan here: Flutter is fun'), findsOneWidget);
    await t.pageBack();
    await settle(t);
    await tapText(t, 'Saved Posts');
    expect(find.text('Dan here: Flutter is fun'), findsOneWidget);
    await t.tap(find.text('Saved'));
    await settle(t, 3);
    expect(find.text('You have no saved posts.'), findsOneWidget);
    await t.pageBack();
    await settle(t);

    // --- SCR14 Edit Profile ---
    await t.drag(find.byType(ListView).first, const Offset(0, 1500));
    await settle(t, 1);
    await tapKey(t, 'profile_edit_button');
    await typeInto(
      t,
      find.byKey(const Key('edit_name_field')),
      'Carol Vu Updated',
    );
    await typeInto(t, find.byKey(const Key('edit_bio_field')), 'Hello bio');
    await tapKey(t, 'save_profile_button', seconds: 3);
    expect(
      find.byKey(const Key('edit_name_field')),
      findsNothing,
      reason: 'Edit Profile must close after save',
    );
    expect(find.text('Carol Vu Updated'), findsWidgets);

    // --- SCR10 Search, SCR11 Friend Requests, SCR12 Friend List ---
    await tapText(t, 'Search');
    await typeInto(t, find.byType(TextField), 'Dan');
    await settle(t, 3);
    expect(find.text('Dan Pham'), findsWidgets);
    await tapText(t, 'Add Friend', seconds: 3);
    expect(find.text('Request Sent'), findsWidgets);
    // Bob (second user, real API) sends Carol a request -> notification + Received tab.
    final carol =
        (await callApi(
              'POST',
              '/auth/login',
              body: {'phone': phone, 'password': 'abcd1234'},
            ))['data']
            as Map<String, dynamic>;
    final bob =
        (await callApi(
              'POST',
              '/auth/login',
              body: {'phone': '0900000002', 'password': 'abcd1234'},
            ))['data']
            as Map<String, dynamic>;
    final sent = await callApi(
      'POST',
      '/friends/requests',
      token: bob['token'] as String,
      body: {'receiver_id': (carol['user'] as Map<String, dynamic>)['id']},
    );
    expect(sent['success'], true);

    await tapText(t, 'Friends');
    await tapTextContaining(t, 'Requests', seconds: 3);
    expect(find.text('Bob Tran'), findsWidgets);
    await tapText(t, 'Accept', seconds: 3);
    await tapTextContaining(t, 'Sent');
    expect(find.text('Dan Pham'), findsWidgets);
    await tapText(t, 'Cancel Request', seconds: 3);
    await t.pageBack();
    await settle(t);
    await t.pump(const Duration(seconds: 2));
    expect(
      find.text('Bob Tran'),
      findsWidgets,
      reason: 'accepted friend must be in the Friend List',
    );

    // --- SCR03 Notifications ---
    await tapText(t, 'Home');
    await t.tap(find.byTooltip('Notifications'));
    await settle(t, 3);
    expect(find.textContaining('Bob Tran'), findsWidgets);
    await tapText(t, 'Mark all read', seconds: 3);
    expect(find.textContaining('new'), findsNothing);
    await t.pageBack();
    await settle(t);

    // --- SCR15 Account Settings: wrong, mismatch, success; logout; relogin ---
    await tapText(t, 'Profile');
    await tapKey(t, 'profileSettingsButton');
    final fields = find.byType(TextFormField);
    await typeInto(t, fields.at(0), 'wrongpass1');
    await typeInto(t, fields.at(1), 'newpass99');
    await typeInto(t, fields.at(2), 'newpass99');
    await t.tap(find.widgetWithText(FilledButton, 'Change Password'));
    await settle(t, 3);
    expect(find.text('Current password is incorrect.'), findsOneWidget);
    await typeInto(t, fields.at(0), 'abcd1234');
    await typeInto(t, fields.at(2), 'different99');
    await t.tap(find.widgetWithText(FilledButton, 'Change Password'));
    await settle(t, 1);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await typeInto(t, fields.at(2), 'newpass99');
    await t.tap(find.widgetWithText(FilledButton, 'Change Password'));
    await settle(t, 3);
    expect(find.text('Changes saved successfully.'), findsOneWidget);
    await tapText(t, 'Log Out');
    await t.tap(find.widgetWithText(FilledButton, 'Log Out'));
    await settle(t, 3);
    expect(find.text('Phone Number'), findsOneWidget);
  });
}
