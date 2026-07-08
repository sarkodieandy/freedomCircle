class AppException implements Exception {
  const AppException(this.message, {this.code, this.cause});

  final String message;
  final String? code;
  final Object? cause;

  @override
  String toString() => message;
}

class AuthException extends AppException {
  const AuthException(super.message, {super.code, super.cause});
}

class NetworkException extends AppException {
  const NetworkException(super.message, {super.code, super.cause});
}

class PermissionException extends AppException {
  const PermissionException(super.message, {super.code, super.cause});
}

class ValidationException extends AppException {
  const ValidationException(super.message, {super.code, super.cause});
}

class PaymentException extends AppException {
  const PaymentException(super.message, {super.code, super.cause});
}

class UnknownException extends AppException {
  const UnknownException(super.message, {super.code, super.cause});
}
