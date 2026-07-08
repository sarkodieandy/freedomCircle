class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthFlowController {
  const AuthFlowController();

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 720));
    if (!_looksLikeEmail(email)) {
      throw const AuthFlowException('Enter a valid email address.');
    }
    if (password.length < 6) {
      throw const AuthFlowException('Password must be at least 6 characters.');
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
    await Future<void>.delayed(const Duration(milliseconds: 820));
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
  }

  Future<void> sendPasswordReset(String email) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!_looksLikeEmail(email)) {
      throw const AuthFlowException('Enter the email linked to your account.');
    }
  }

  Future<void> verifyOtp(String code) async {
    await Future<void>.delayed(const Duration(milliseconds: 640));
    if (code.length != 6) {
      throw const AuthFlowException('Enter the full 6-digit code.');
    }
  }

  Future<void> signOut() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
  }

  bool _looksLikeEmail(String value) {
    final trimmed = value.trim();
    return trimmed.contains('@') && trimmed.contains('.');
  }
}
