import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/model_helpers.dart';
import '../supabase/supabase_service.dart';

class SupabaseRepositoryException implements Exception {
  const SupabaseRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract class SupabaseRepository {
  const SupabaseRepository({this.supabaseClient});

  final SupabaseClient? supabaseClient;

  SupabaseClient get client => supabaseClient ?? SupabaseService.client;

  Future<T> guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on PostgrestException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SupabaseRepositoryException(error.message),
        stackTrace,
      );
    } on AuthException catch (error, stackTrace) {
      Error.throwWithStackTrace(
        SupabaseRepositoryException(error.message),
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
