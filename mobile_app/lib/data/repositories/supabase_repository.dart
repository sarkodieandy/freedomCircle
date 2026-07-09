import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../models/model_helpers.dart';
import '../supabase/supabase_service.dart';

abstract class SupabaseRepository {
  const SupabaseRepository({this.supabaseClient});

  final sb.SupabaseClient? supabaseClient;

  sb.SupabaseClient get client => supabaseClient ?? SupabaseService.client;

  Future<T> guard<T>(
    Future<T> Function() operation, {
    String? source,
    String? table,
    Object? data,
  }) async {
    final resolvedSource = source ?? _callerFromStack(StackTrace.current);
    final userId = SupabaseService.currentUserId;

    AppLogger.supabase(
      'Method started',
      table: table,
      data: {'source': resolvedSource, 'user_id': userId, 'context': ?data},
    );

    try {
      final result = await operation();
      AppLogger.supabase(
        'Method success',
        table: table,
        data: {
          'source': resolvedSource,
          'user_id': userId,
          'result_count': _resultCount(result),
        },
      );
      return result;
    } on sb.PostgrestException catch (error, stackTrace) {
      final message = error.message.toLowerCase();
      final exception = switch (error.code) {
        'PGRST301' || '42501' => PermissionException(
          error.message,
          source: resolvedSource,
          code: error.code,
          originalError: error,
          stackTrace: stackTrace,
        ),
        _
            when message.contains('permission') ||
                message.contains('forbidden') =>
          PermissionException(
            error.message,
            source: resolvedSource,
            code: error.code,
            originalError: error,
            stackTrace: stackTrace,
          ),
        _
            when message.contains('row-level security') ||
                message.contains('rls') =>
          PermissionException(
            'RLS policy blocked this request.',
            source: resolvedSource,
            code: error.code,
            originalError: error,
            stackTrace: stackTrace,
          ),
        _ when message.contains('validation') || message.contains('invalid') =>
          ValidationException(
            error.message,
            source: resolvedSource,
            code: error.code,
            originalError: error,
            stackTrace: stackTrace,
          ),
        _ => AppException(
          error.message,
          code: error.code,
          source: resolvedSource,
          originalError: error,
          stackTrace: stackTrace,
        ),
      };

      AppLogger.error(
        'Method failed',
        tag: 'SUPABASE',
        error: error,
        stackTrace: stackTrace,
        data: {
          'source': resolvedSource,
          'table': table,
          'code': error.code,
          'user_id': userId,
        },
      );

      Error.throwWithStackTrace(exception, stackTrace);
    } on sb.AuthException catch (error, stackTrace) {
      AppLogger.error(
        'Authentication failure in repository method',
        tag: 'AUTH',
        error: error,
        stackTrace: stackTrace,
        data: {'source': resolvedSource, 'table': table, 'user_id': userId},
      );

      Error.throwWithStackTrace(
        AuthException(
          error.message,
          source: resolvedSource,
          originalError: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    } on SocketException catch (error, stackTrace) {
      AppLogger.error(
        'Network failure in repository method',
        tag: 'DATABASE',
        error: error,
        stackTrace: stackTrace,
        data: {'source': resolvedSource, 'table': table},
      );

      Error.throwWithStackTrace(
        NetworkException(
          'Network unavailable. Please check your connection.',
          source: resolvedSource,
          originalError: error,
          stackTrace: stackTrace,
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      final rawMessage = _extractMessage(error);
      final message = rawMessage ?? 'Something went wrong while loading data.';
      final typeName = error.runtimeType.toString().toLowerCase();

      final exception = switch (typeName) {
        _ when typeName.contains('auth') => AuthException(
          message,
          source: resolvedSource,
          originalError: error,
          stackTrace: stackTrace,
        ),
        _
            when typeName.contains('network') ||
                typeName.contains('socket') ||
                typeName.contains('timeout') =>
          NetworkException(
            message,
            source: resolvedSource,
            originalError: error,
            stackTrace: stackTrace,
          ),
        _
            when typeName.contains('permission') ||
                typeName.contains('forbidden') =>
          PermissionException(
            message,
            source: resolvedSource,
            originalError: error,
            stackTrace: stackTrace,
          ),
        _ => UnknownException(
          message,
          source: resolvedSource,
          originalError: error,
          stackTrace: stackTrace,
        ),
      };

      AppLogger.error(
        'Unexpected repository failure',
        tag: 'ERROR',
        error: error,
        stackTrace: stackTrace,
        data: {'source': resolvedSource, 'table': table, 'user_id': userId},
      );

      Error.throwWithStackTrace(exception, stackTrace);
    }
  }

  String? _extractMessage(Object error) {
    try {
      final dynamic dynamicError = error;
      final dynamic message = dynamicError.message;
      if (message is String) {
        final normalized = _normalizeMessage(message);
        if (normalized != null) return normalized;
      }
    } catch (_) {
      // No strongly-typed message field available.
    }

    final normalized = _normalizeMessage(error.toString());
    return normalized;
  }

  String? _normalizeMessage(String value) {
    var text = value.trim();
    if (text.isEmpty) return null;

    const prefixes = ['exception: ', 'error: ', 'unknownexception: '];
    final lower = text.toLowerCase();
    for (final prefix in prefixes) {
      if (lower.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
        break;
      }
    }

    if (text.isEmpty) return null;
    return text;
  }

  String _callerFromStack(StackTrace stackTrace) {
    final lines = stackTrace.toString().split('\n');
    for (final line in lines) {
      if (line.contains('SupabaseRepository.guard')) continue;
      if (line.contains('package:flutter/')) continue;
      if (line.contains('dart:')) continue;
      final match = RegExp(r'#\d+\s+([^\s]+)').firstMatch(line);
      final candidate = match?.group(1);
      if (candidate != null && candidate.isNotEmpty) return candidate;
    }
    return runtimeType.toString();
  }

  int? _resultCount(Object? result) {
    if (result is List) return result.length;
    if (result is Map) return result.isEmpty ? 0 : 1;
    return null;
  }

  JsonMap mapRow(Object? value) => asJsonMap(value);

  List<T> mapRows<T>(Object? value, T Function(JsonMap map) mapper) {
    final rows = value as List;
    return rows.map((item) => mapper(asJsonMap(item))).toList();
  }
}
