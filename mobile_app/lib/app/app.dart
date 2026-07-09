import 'package:flutter/material.dart';

import '../core/services/app_state.dart';
import '../core/utils/app_logger.dart';
import 'routes.dart';
import 'theme.dart';

class FreedomCircleApp extends StatefulWidget {
  const FreedomCircleApp({super.key});

  @override
  State<FreedomCircleApp> createState() => _FreedomCircleAppState();
}

class _FreedomCircleAppState extends State<FreedomCircleApp> {
  final appState = AppState();
  final NavigatorObserver _navigationObserver = _AppNavigationObserver();

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
        title: 'freedonCircle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        initialRoute: AppRoutes.launch,
        onGenerateRoute: AppRoutes.onGenerateRoute,
        navigatorObservers: [_navigationObserver],
      ),
    );
  }
}

class _AppNavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.navigation(
      'Route changed (push)',
      data: {
        'to': route.settings.name ?? route.runtimeType.toString(),
        'from': previousRoute?.settings.name,
      },
    );
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    AppLogger.navigation(
      'Route changed (pop)',
      data: {
        'to': previousRoute?.settings.name,
        'from': route.settings.name ?? route.runtimeType.toString(),
      },
    );
    super.didPop(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    AppLogger.navigation(
      'Route changed (replace)',
      data: {'to': newRoute?.settings.name, 'from': oldRoute?.settings.name},
    );
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }
}
