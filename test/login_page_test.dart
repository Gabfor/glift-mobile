import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase/supabase.dart';

import 'package:glift_mobile/auth/auth_repository.dart';
import 'package:glift_mobile/login_page.dart';

class FakeAuthRepository implements AuthRepository {
  bool shouldThrowAuth = false;
  bool shouldThrow = false;
  String message =
      'Identifiants invalides. Vérifiez votre email et votre mot de passe.';
  Future<void> Function()? onSignIn;

  @override
  Future<void> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (onSignIn != null) {
      await onSignIn!();
    }

    if (shouldThrowAuth) {
      throw AuthException(message);
    }

    if (shouldThrow) {
      throw Exception('Unexpected error');
    }
  }

  @override
  Future<void> sendPasswordReset({required String email}) async {}
}

final _supabase = SupabaseClient(
  'https://test.supabase.co',
  'public-anon-key',
);

Widget _buildLogin(FakeAuthRepository repository) {
  return MaterialApp(
    home: LoginPage(
      authRepository: repository,
      supabase: _supabase,
    ),
  );
}

void main() {
  testWidgets('Login button disabled until form valid and loading finishes',
      (tester) async {
    final repository = FakeAuthRepository();
    final completer = Completer<void>();
    repository.onSignIn = () => completer.future;

    await tester.pumpWidget(_buildLogin(repository));

    final buttonFinder = find.byKey(const Key('loginButton'));
    expect(buttonFinder, findsOneWidget);

    ElevatedButton button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);

    await tester.enterText(find.byKey(const Key('emailInput')),
        'john.doe@email.com');
    await tester.pump();

    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);

    await tester.enterText(find.byKey(const Key('passwordInput')), 'secret1');
    await tester.pump();

    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNotNull);

    await tester.tap(buttonFinder);
    await tester.pump();

    button = tester.widget(buttonFinder);
    expect(button.onPressed, isNull);

    completer.complete();
    await tester.pumpAndSettle();
  });

  testWidgets('Password toggle switches obscureText', (tester) async {
    final repository = FakeAuthRepository();

    await tester.pumpWidget(_buildLogin(repository));

    final passwordField = find.byKey(const Key('passwordInput'));
    final toggleButton = find.byKey(const Key('passwordToggle'));

    TextField textField = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(TextField)),
    );
    expect(textField.obscureText, isTrue);

    await tester.tap(toggleButton);
    await tester.pump();

    textField = tester.widget(
      find.descendant(of: passwordField, matching: find.byType(TextField)),
    );
    expect(textField.obscureText, isFalse);
  });

  testWidgets('Validation errors appear on submit when fields empty',
      (tester) async {
    final repository = FakeAuthRepository();

    await tester.pumpWidget(_buildLogin(repository));

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pump();

    expect(find.text('Veuillez saisir un email valide.'), findsOneWidget);
    expect(find.text('Veuillez saisir votre mot de passe.'), findsNothing);
  });

  testWidgets('Supabase auth error is displayed', (tester) async {
    final repository = FakeAuthRepository()
      ..shouldThrowAuth = true
      ..message = 'Identifiants invalides. Vérifiez votre email et votre mot de passe.';

    await tester.pumpWidget(_buildLogin(repository));

    await tester.enterText(
        find.byKey(const Key('emailInput')), 'john.doe@email.com');
    await tester.enterText(find.byKey(const Key('passwordInput')), 'secret1');

    await tester.tap(find.byKey(const Key('loginButton')));
    await tester.pumpAndSettle();

    expect(
      find.text('Identifiants invalides. Vérifiez votre email et votre mot de passe.'),
      findsOneWidget,
    );
  });
}
