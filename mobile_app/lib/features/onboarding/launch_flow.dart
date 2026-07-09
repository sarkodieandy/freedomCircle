import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/utils/app_logger.dart';
import '../../data/repositories/profile_repository.dart';
import '../../data/supabase/supabase_service.dart';
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
  final ProfileRepository _profileRepository = const ProfileRepository();
  sb.AuthChangeEvent? _lastAuthEvent;

  int stage = -1;
  AuthMode authMode = AuthMode.login;

  @override
  void initState() {
    super.initState();
    _bootstrapLaunchStage();
    if (SupabaseService.isInitialized) {
      SupabaseService.authStateChanges.listen((state) {
        _lastAuthEvent = state.event;
        if (!mounted) return;
        if (state.event == sb.AuthChangeEvent.signedOut) {
          setState(() {
            authMode = AuthMode.login;
            stage = 2;
          });
          _logStage('signed_out');
        }
      });
    }
  }

  void _next() {
    setState(() => stage = (stage + 1).clamp(0, 5));
    _logStage('next');
  }

  Future<void> _bootstrapLaunchStage() async {
    AppLogger.navigation(
      'Launch flow started',
      data: {
        'supabase_initialized': SupabaseService.isInitialized,
        'session_exists': SupabaseService.currentSession != null,
      },
    );

    if (!SupabaseService.isInitialized ||
        SupabaseService.currentSession == null) {
      if (!mounted) return;
      setState(() => stage = 0);
      _logStage('bootstrap_no_session');
      return;
    }

    await _resolvePostAuthDestination(source: 'bootstrap_existing_session');
  }

  Future<void> _resolvePostAuthDestination({required String source}) async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      if (!mounted) return;
      setState(() => stage = 2);
      _logStage('$source -> no_user_auth_welcome');
      return;
    }

    try {
      final profile = await _profileRepository.getProfileByUserId(user.id);
      if (!mounted) return;
      final onboardingComplete = profile?.isOnboardingCompleted ?? false;
      setState(() => stage = onboardingComplete ? 5 : 4);
      _logStage('$source -> ${onboardingComplete ? 'home' : 'setup_flow'}');
    } catch (error) {
      if (!mounted) return;
      AppLogger.warning(
        'Launch profile gate failed. Falling back to setup flow.',
        tag: 'NAVIGATION',
        data: {'error': error.toString()},
      );
      setState(() => stage = 4);
      _logStage('$source -> setup_fallback');
    }
  }

  Future<void> _onAuthenticated() async {
    await _resolvePostAuthDestination(source: 'auth_success');
  }

  void _openAuth(AuthMode mode) {
    setState(() {
      authMode = mode;
      stage = 3;
    });
    AppLogger.navigation(
      'Auth entry selected',
      data: {'mode': mode.name, 'stage': stage},
    );
  }

  void _logStage(String action) {
    final stageName = switch (stage) {
      -1 => 'checking',
      0 => 'splash',
      1 => 'onboarding',
      2 => 'auth_welcome',
      3 => 'auth',
      4 => 'setup_flow',
      _ => 'home',
    };

    AppLogger.navigation(
      'LaunchFlow stage changed',
      data: {
        'action': action,
        'stage': stage,
        'stage_name': stageName,
        'auth_event': _lastAuthEvent?.name,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      child: switch (stage) {
        -1 => const Scaffold(
          body: SafeArea(child: Center(child: CircularProgressIndicator())),
        ),
        0 => SplashScreen(onContinue: _next),
        1 => OnboardingScreen(onFinished: _next),
        2 => AuthWelcomeScreen(
          onCreateAccount: () => _openAuth(AuthMode.signup),
          onLogin: () => _openAuth(AuthMode.login),
        ),
        3 => AuthScreen(
          key: ValueKey(authMode),
          initialMode: authMode,
          onAuthenticated: _onAuthenticated,
        ),
        4 => SetupFlowScreen(onComplete: _next),
        _ => const FreedomShell(),
      },
    );
  }
}
