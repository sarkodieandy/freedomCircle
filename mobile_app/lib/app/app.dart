import 'package:flutter/material.dart';

import '../core/services/app_state.dart';
import '../features/onboarding/launch_flow.dart';
import 'routes.dart';
import 'theme.dart';

class FreedomCircleApp extends StatefulWidget {
  const FreedomCircleApp({super.key});

  @override
  State<FreedomCircleApp> createState() => _FreedomCircleAppState();
}

class _FreedomCircleAppState extends State<FreedomCircleApp> {
  final appState = AppState();

  @override
  void dispose() {
    appState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      notifier: appState,
      child: MaterialApp(
        title: 'FreedomCircle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        home: const LaunchFlow(),
      ),
    );
  }
}
