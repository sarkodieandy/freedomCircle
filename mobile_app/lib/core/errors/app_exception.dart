class AppException implements Exception {
  const AppException(
    this.message, {
    this.code,
    this.source,
    Object? cause,
    Object? originalError,
    this.stackTrace,
  }) : originalError = originalError ?? cause;

  final String message;
  final String? code;
  final String? source;
  final Object? originalError;
  final StackTrace? stackTrace;

  @Deprecated('Use originalError instead')
  Object? get cause => originalError;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.source,
    super.cause,
    super.originalError,
    super.stackTrace,
  });
}

class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.source,
    super.cause,
    super.originalError,
    super.stackTrace,
  });
}

class PermissionException extends AppException {
  const PermissionException(
    super.message, {
    super.code,
    super.source,
    super.cause,
    super.originalError,
    super.stackTrace,
  });
}

class ValidationException extends AppException {
  const ValidationException(
    super.message, {
    super.code,
    super.source,
    super.cause,
    super.originalError,
    super.stackTrace,
  });
}

class PaymentException extends AppException {
  const PaymentException(
    super.message, {
    super.code,
    super.source,
    super.cause,
    super.originalError,
    super.stackTrace,
  });
}

class UnknownException extends AppException {
  const UnknownException(
    super.message, {
    super.code,
    super.source,
    super.cause,
    super.originalError,
    super.stackTrace,
  });
}
