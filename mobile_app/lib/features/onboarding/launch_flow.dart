import 'package:flutter/material.dart';

import '../auth/auth_screen.dart';
import '../auth/auth_welcome_screen.dart';
import 'setup_flow_screen.dart';
import '../home/freedom_shell.dart';
import 'onboarding_screen.dart';
import 'splash_screen.dart';

class LaunchFlow extends StatefulWidget {
  const LaunchFlow({super.key});

  @override
  State<LaunchFlow> createState() => _LaunchFlowState();
}

class _LaunchFlowState extends State<LaunchFlow> {
  int stage = 0;
  AuthMode authMode = AuthMode.login;

  void _next() {
    setState(() => stage = (stage + 1).clamp(0, 5));
  }

  void _openAuth(AuthMode mode) {
    setState(() {
      authMode = mode;
      stage = 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: switch (stage) {
        0 => SplashScreen(onContinue: _next),
        1 => OnboardingScreen(onFinished: _next),
        2 => AuthWelcomeScreen(
          onCreateAccount: () => _openAuth(AuthMode.signup),
          onLogin: () => _openAuth(AuthMode.login),
        ),
        3 => AuthScreen(
          key: ValueKey(authMode),
          initialMode: authMode,
          onAuthenticated: _next,
        ),
        4 => SetupFlowScreen(onComplete: _next),
        _ => const FreedomShell(),
      },
    );
  }
}
