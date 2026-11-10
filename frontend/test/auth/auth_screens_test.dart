import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:clone_facebook/features/auth/auth_provider.dart';
import 'package:clone_facebook/features/auth/login_screen.dart';
import 'package:clone_facebook/features/auth/register_screen.dart';

/// Records what the forms submit; no network.
class RecordingAuth extends AuthStateNotifier {
  static final calls = <List<Object?>>[];

  @override
  Future<bool> login(String identifier, String password) async {
    calls.add(['login', identifier, password]);
    return false;
  }

  @override
  Future<bool> register({
    required String fullName,
    String? email,
    required String phone,
    required String password,
    DateTime? birthday,
    String? gender,
  }) async {
    calls.add(['register', fullName, phone, password, email, birthday]);
    return false;
  }
}

Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  RecordingAuth.calls.clear();
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [authStateProvider.overrideWith(RecordingAuth.new)],
      child: MaterialApp(home: screen),
    ),
  );
}

Future<void> fill(WidgetTester tester, String key, String text) async {
  await tester.enterText(find.byKey(Key(key)), text);
}

Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pump();
}

void main() {
  group('Login (SCR16)', () {
    testWidgets('asks for a phone number and rejects empty or invalid input', (
      tester,
    ) async {
      await pumpScreen(tester, const LoginScreen());
      expect(find.text('Phone Number'), findsOneWidget);
      expect(find.textContaining('Email'), findsNothing);

      await tapKey(tester, 'loginSubmitButton');
      expect(find.text('Please enter the required information.'), findsWidgets);

      await fill(tester, 'loginEmailField', '123');
      await fill(tester, 'loginPasswordField', 'abcd1234');
      await tapKey(tester, 'loginSubmitButton');
      expect(find.textContaining('valid phone number'), findsOneWidget);
      expect(RecordingAuth.calls, isEmpty);
    });

    testWidgets('phone field only accepts digits and +, max 16 characters', (
      tester,
    ) async {
      await pumpScreen(tester, const LoginScreen());
      await fill(tester, 'loginEmailField', 'ab 09-12.34x5678');
      expect(find.text('0912345678'), findsWidgets);
      await fill(tester, 'loginEmailField', '+8412345678901234567890');
      expect(find.text('+841234567890123'), findsWidgets);
    });

    testWidgets('submits phone and password', (tester) async {
      await pumpScreen(tester, const LoginScreen());
      await fill(tester, 'loginEmailField', '0912345678');
      await fill(tester, 'loginPasswordField', 'abcd1234');
      await tapKey(tester, 'loginSubmitButton');
      expect(RecordingAuth.calls, [
        ['login', '0912345678', 'abcd1234'],
      ]);
    });
  });

  group('Register (SCR17)', () {
    testWidgets('shows only Name, Phone, Password fields', (tester) async {
      await pumpScreen(tester, const RegisterScreen());
      expect(find.byKey(const Key('registerFullNameField')), findsOneWidget);
      expect(find.byKey(const Key('registerPhoneField')), findsOneWidget);
      expect(find.byKey(const Key('registerPasswordField')), findsOneWidget);
      expect(find.byKey(const Key('registerEmailField')), findsNothing);
      expect(find.byKey(const Key('registerBirthdayField')), findsNothing);
    });

    testWidgets('blocks submit when phone is missing', (tester) async {
      await pumpScreen(tester, const RegisterScreen());
      await fill(tester, 'registerFullNameField', 'An Nguyen');
      await fill(tester, 'registerPasswordField', 'abcd1234');
      await fill(tester, 'registerConfirmPasswordField', 'abcd1234');
      await tapKey(tester, 'registerSubmitButton');
      expect(find.text('Please enter the required information.'), findsOneWidget);
      expect(RecordingAuth.calls, isEmpty);
    });

    testWidgets('submits name, phone and password without email/birthday', (
      tester,
    ) async {
      await pumpScreen(tester, const RegisterScreen());
      await fill(tester, 'registerFullNameField', 'An Nguyen');
      await fill(tester, 'registerPhoneField', '0912345678');
      await fill(tester, 'registerPasswordField', 'abcd1234');
      await fill(tester, 'registerConfirmPasswordField', 'abcd1234');
      await tapKey(tester, 'registerSubmitButton');
      expect(RecordingAuth.calls, [
        ['register', 'An Nguyen', '0912345678', 'abcd1234', null, null],
      ]);
    });
  });
}
