import '../../core/errors/app_exception.dart';
import '../../data/repositories/auth_repository.dart';

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthFlowController {
  const AuthFlowController({this.authRepository = const AuthRepository()});

  final AuthRepository authRepository;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (!_looksLikeEmail(email)) {
      throw const AuthFlowException('Enter a valid email address.');
    }
    if (password.length < 6) {
      throw const AuthFlowException('Password must be at least 6 characters.');
    }
    try {
      await authRepository.signInWithEmail(
        email: email.trim(),
        password: password,
      );
    } on AppException catch (error) {
      throw AuthFlowException(error.message);
    }
  }

  Future<void> signUpWithEmail({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? phone,
    required bool acceptedTerms,
  }) async {
    if (fullName.trim().length < 2) {
      throw const AuthFlowException('Add your full name.');
    }
    if (username.trim().length < 3) {
      throw const AuthFlowException('Choose a username with 3+ characters.');
    }
    if (!_looksLikeEmail(email)) {
      throw const AuthFlowException('Enter a valid email address.');
    }
    if (password.length < 8) {
      throw const AuthFlowException('Use at least 8 characters for password.');
    }
    if (password != confirmPassword) {
      throw const AuthFlowException('Passwords do not match.');
    }
    if (!acceptedTerms) {
      throw const AuthFlowException('Accept the terms and privacy promise.');
    }
    try {
      await authRepository.signUpWithEmail(
        fullName: fullName.trim(),
        username: username.trim(),
        email: email.trim(),
        password: password,
        phone: phone?.trim(),
      );
    } on AppException catch (error) {
      throw AuthFlowException(error.message);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_looksLikeEmail(email)) {
      throw const AuthFlowException('Enter the email linked to your account.');
    }
    try {
      await authRepository.sendPasswordReset(email.trim());
    } on AppException catch (error) {
      throw AuthFlowException(error.message);
    }
  }

  Future<void> verifyOtp(String code, {String? emailOrPhone}) async {
    if (code.length != 6) {
      throw const AuthFlowException('Enter the full 6-digit code.');
    }
    final target = emailOrPhone?.trim();
    if (target == null || target.isEmpty) {
      return;
    }
    try {
      await authRepository.verifyOtp(emailOrPhone: target, token: code);
    } on AppException catch (error) {
      throw AuthFlowException(error.message);
    }
  }

  Future<void> signOut() async {
    try {
      await authRepository.signOut();
    } on AppException catch (error) {
      throw AuthFlowException(error.message);
    }
  }

  bool _looksLikeEmail(String value) {
    final trimmed = value.trim();
    return trimmed.contains('@') && trimmed.contains('.');
  }
}
