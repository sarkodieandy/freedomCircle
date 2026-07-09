import 'dart:ui';

import 'package:flutter/material.dart';

import 'app/app.dart';
import 'core/services/monetization_service.dart';
import 'core/services/revenuecat_service.dart';
import 'core/utils/app_logger.dart';
import 'data/supabase/supabase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  AppLogger.info('App starting', tag: 'UI', data: {'module': 'main'});

  FlutterError.onError = (details) {
    AppLogger.error(
      'Flutter framework error',
      tag: 'UI',
      error: details.exception,
      stackTrace: details.stack,
      data: {
        'library': details.library,
        'context': details.context?.toString(),
      },
    );
    FlutterError.presentError(details);
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.error(
      'Uncaught async error',
      tag: 'ERROR',
      error: error,
      stackTrace: stack,
    );
    return true;
  };

  ErrorWidget.builder = (FlutterErrorDetails details) {
    AppLogger.error(
      'ErrorWidget rendered after framework exception',
      tag: 'UI',
      error: details.exception,
      stackTrace: details.stack,
    );
    return Material(
      color: const Color(0xFFFAF8F2),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong. Please restart the app.',
            style: const TextStyle(fontSize: 16, color: Color(0xFF172033)),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  };

  try {
    AppLogger.supabase(
      'Supabase initialization started',
      data: {'module': 'main'},
    );
    await SupabaseService.initialize();
    AppLogger.supabase(
      'Supabase initialization success',
      data: {
        'module': 'main',
        'initialized': SupabaseService.isInitialized,
        'session_exists': SupabaseService.currentSession != null,
      },
    );
  } catch (error, stackTrace) {
    AppLogger.error(
      'Supabase initialization failed',
      tag: 'SUPABASE',
      error: error,
      stackTrace: stackTrace,
    );
  }

  if (SupabaseService.isInitialized) {
    try {
      AppLogger.info('RevenueCat initialization started', tag: 'REVENUECAT');
      await RevenueCatService.instance.initialize();
      AppLogger.info('RevenueCat initialization success', tag: 'REVENUECAT');
    } catch (error, stackTrace) {
      AppLogger.error(
        'RevenueCat initialization failed',
        tag: 'REVENUECAT',
        error: error,
        stackTrace: stackTrace,
      );
    }

    if (RevenueCatService.instance.isInitialized) {
      try {
        await MonetizationService.instance.initializePremiumWatcher();
      } catch (error, stackTrace) {
        AppLogger.error(
          'Premium watcher initialization failed',
          tag: 'PAYMENT',
          error: error,
          stackTrace: stackTrace,
        );
      }
    } else {
      AppLogger.warning(
        'Premium watcher skipped because RevenueCat is not initialized',
        tag: 'PAYMENT',
      );
    }
  }

  runApp(const FreedomCircleApp());
}
