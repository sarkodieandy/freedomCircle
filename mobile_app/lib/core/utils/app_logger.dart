import 'dart:convert';

import 'package:flutter/foundation.dart';

const bool appDebugLogsEnabled = kDebugMode;

class AppLogger {
  const AppLogger._();

  static void debug(String message, {String? tag, Object? data}) {
    _log('DEBUG', message, tag: tag ?? 'UI', data: data);
  }

  static void info(String message, {String? tag, Object? data}) {
    _log('INFO', message, tag: tag ?? 'UI', data: data);
  }

  static void warning(String message, {String? tag, Object? data}) {
    _log('WARN', message, tag: tag ?? 'UI', data: data);
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    _log(
      'ERROR',
      message,
      tag: tag ?? 'ERROR',
      error: error,
      stackTrace: stackTrace,
      data: data,
    );
  }

  static void api(String message, {String? endpoint, Object? data}) {
    _log(
      'INFO',
      message,
      tag: 'DATABASE',
      data: {'endpoint': ?endpoint, 'data': ?data},
    );
  }

  static void supabase(String message, {String? table, Object? data}) {
    _log(
      'INFO',
      message,
      tag: 'SUPABASE',
      data: {'table': ?table, 'data': ?data},
    );
  }

  static void auth(String message, {Object? data}) {
    _log('INFO', message, tag: 'AUTH', data: data);
  }

  static void navigation(String message, {Object? data}) {
    _log('INFO', message, tag: 'NAVIGATION', data: data);
  }

  static void payment(String message, {Object? data}) {
    _log('INFO', message, tag: 'PAYMENT', data: data);
  }

  static void chat(String message, {Object? data}) {
    _log('INFO', message, tag: 'CHAT', data: data);
  }

  static void _log(
    String level,
    String message, {
    required String tag,
    Object? error,
    StackTrace? stackTrace,
    Object? data,
  }) {
    if (!appDebugLogsEnabled) return;

    final ts = DateTime.now()
        .toIso8601String()
        .replaceFirst('T', ' ')
        .split('.')
        .first;
    final parts = <String>['[$ts]', '[${tag.toUpperCase()}]'];
    parts.add(message);

    debugPrint(parts.join(' '));

    if (data != null) {
      final safeData = sanitizeLogData(data);
      debugPrint('Data: ${_toReadable(safeData)}');
    }

    if (error != null) {
      debugPrint('Error: ${_toReadable(sanitizeLogData(error.toString()))}');
    }

    if (stackTrace != null) {
      debugPrint('StackTrace:');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  static dynamic sanitizeLogData(dynamic data) {
    if (data == null) return null;

    if (data is Map) {
      final sanitized = <String, dynamic>{};
      data.forEach((key, value) {
        final normalizedKey = key.toString().toLowerCase();
        if (_isSensitiveField(normalizedKey)) {
          sanitized[key.toString()] = '[REDACTED]';
        } else {
          sanitized[key.toString()] = sanitizeLogData(value);
        }
      });
      return sanitized;
    }

    if (data is Iterable) {
      return data.map(sanitizeLogData).toList(growable: false);
    }

    if (data is String) {
      if (_looksSensitiveText(data)) return '[REDACTED]';
      return data;
    }

    return data;
  }

  static bool _isSensitiveField(String key) {
    const sensitiveFields = [
      'password',
      'token',
      'access_token',
      'refresh_token',
      'anon_key',
      'service_role',
      'secret',
      'api_key',
      'authorization',
      'otp',
      'pin',
      'private_note',
      'journal',
      'recovery_note',
      'reflection_note',
    ];

    for (final field in sensitiveFields) {
      if (key.contains(field)) return true;
    }
    return false;
  }

  static bool _looksSensitiveText(String value) {
    final lower = value.toLowerCase();
    return _isSensitiveField(lower);
  }

  static String _toReadable(Object? value) {
    try {
      return const JsonEncoder.withIndent('  ').convert(value);
    } catch (_) {
      return value.toString();
    }
  }
}
