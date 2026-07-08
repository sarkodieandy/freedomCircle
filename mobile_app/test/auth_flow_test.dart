import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/app/theme.dart';
import 'package:mobile_app/features/auth/auth_screen.dart';
import 'package:mobile_app/features/auth/auth_welcome_screen.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(theme: AppTheme.light, home: child);
  }

  testWidgets('auth welcome offers account and login without social buttons', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(AuthWelcomeScreen(onCreateAccount: () {}, onLogin: () {})),
    );

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.textContaining('Your journey stays private'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Facebook'), findsNothing);
    expect(find.textContaining('Apple'), findsNothing);
  });

  testWidgets('signup screen includes private account fields', (tester) async {
    await tester.pumpWidget(
      wrap(AuthScreen(initialMode: AuthMode.signup, onAuthenticated: () {})),
    );

    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Full name'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    expect(find.text('Phone optional'), findsOneWidget);
    expect(find.textContaining('Google'), findsNothing);
    expect(find.textContaining('Facebook'), findsNothing);
    expect(find.textContaining('Apple'), findsNothing);
  });
}
