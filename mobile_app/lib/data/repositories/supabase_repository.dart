import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart';
import '../models/model_helpers.dart';
import '../supabase/supabase_service.dart';

abstract class SupabaseRepository {
  const SupabaseRepository({this.supabaseClient});

  final sb.SupabaseClient? supabaseClient;

  sb.SupabaseClient get client => supabaseClient ?? SupabaseService.client;

  Future<T> guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on sb.PostgrestException catch (error, stackTrace) {
      final message = error.message.toLowerCase();
      final exception = switch (error.code) {
        'PGRST301' ||
        '42501' => PermissionException(error.message, cause: error),
        _
            when message.contains('permission') ||
                message.contains('forbidden') =>
          PermissionException(error.message, cause: error),
        _ when message.contains('validation') || message.contains('invalid') =>
          ValidationException(error.message, cause: error),
        _ => AppException(error.message, code: error.code, cause: error),
      };
      Error.throwWithStackTrace(exception, stackTrace);
    } on sb.AuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        AuthException(error.message, cause: error),
        stackTrace,
      );
    } on SocketException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        NetworkException(
          'Network unavailable. Please check your connection.',
          cause: error,
        ),
        stackTrace,
      );
    } catch (error, stackTrace) {
      Error.throwWithStackTrace(
        UnknownException(
          'Something went wrong while loading data.',
          cause: error,
        ),
        stackTrace,
      );
    }
  }

  JsonMap mapRow(Object? value) => asJsonMap(value);

  List<T> mapRows<T>(Object? value, T Function(JsonMap map) mapper) {
    final rows = value as List;
    return rows.map((item) => mapper(asJsonMap(item))).toList();
  }
}
