import '../../core/errors/app_exception.dart';
import '../../core/utils/app_logger.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/profile_repository.dart';

class AuthFlowException implements Exception {
  const AuthFlowException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AuthFlowController {
  const AuthFlowController({
    this.authRepository = const AuthRepository(),
    this.profileRepository = const ProfileRepository(),
  });

  final AuthRepository authRepository;
  final ProfileRepository profileRepository;

  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) async {
    AppLogger.auth(
      'Login button tapped',
      data: {
        'source': 'AuthFlowController.signInWithEmail',
        'email': email.trim(),
      },
    );
    if (!_looksLikeEmail(email)) {
      AppLogger.warning(
        'Login validation failed',
        tag: 'AUTH',
        data: {'reason': 'invalid_email'},
      );
      throw const AuthFlowException('Enter a valid email address.');
    }
    if (password.length < 6) {
      AppLogger.warning(
        'Login validation failed',
        tag: 'AUTH',
        data: {'reason': 'password_too_short'},
      );
      throw const AuthFlowException('Password must be at least 6 characters.');
    }
    try {
      AppLogger.auth('Supabase login started');
      await authRepository.signInWithEmail(
        email: email.trim(),
        password: password,
      );
      AppLogger.auth('Supabase login success');
    } on AppException catch (error) {
      AppLogger.error(
        'Supabase login failed',
        tag: 'AUTH',
        error: error,
        stackTrace: error.stackTrace,
      );
      throw AuthFlowException(error.message);
    } catch (error) {
      AppLogger.error('Supabase login failed', tag: 'AUTH', error: error);
      throw AuthFlowException(_fallbackMessage(error));
    }
  }

  Future<void> signUpWithEmail({
    required String fullName,
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    List<int>? avatarBytes,
    String? phone,
    required bool acceptedTerms,
  }) async {
    final normalizedPhone = _normalizePhone(phone);

    AppLogger.auth(
      'Signup started',
      data: {
        'source': 'AuthFlowController.signUpWithEmail',
        'email': email.trim(),
        'phone_present': normalizedPhone != null,
      },
    );
    if (fullName.trim().length < 2) {
      AppLogger.warning(
        'Signup validation failed',
        tag: 'AUTH',
        data: {'reason': 'full_name'},
      );
      throw const AuthFlowException('Add your full name.');
    }
    if (username.trim().length < 3) {
      AppLogger.warning(
        'Signup validation failed',
        tag: 'AUTH',
        data: {'reason': 'username'},
      );
      throw const AuthFlowException('Choose a username with 3+ characters.');
    }
    if (!_looksLikeEmail(email)) {
      AppLogger.warning(
        'Signup validation failed',
        tag: 'AUTH',
        data: {'reason': 'invalid_email'},
      );
      throw const AuthFlowException('Enter a valid email address.');
    }
    if (password.length < 8) {
      AppLogger.warning(
        'Signup validation failed',
        tag: 'AUTH',
        data: {'reason': 'password_too_short'},
      );
      throw const AuthFlowException('Use at least 8 characters for password.');
    }
    if (password != confirmPassword) {
      AppLogger.warning(
        'Signup validation failed',
        tag: 'AUTH',
        data: {'reason': 'password_mismatch'},
      );
      throw const AuthFlowException('Passwords do not match.');
    }
    if (!acceptedTerms) {
      AppLogger.warning(
        'Signup validation failed',
        tag: 'AUTH',
        data: {'reason': 'terms_not_accepted'},
      );
      throw const AuthFlowException('Accept the terms and privacy promise.');
    }
    if (normalizedPhone != null && normalizedPhone.length < 10) {
      AppLogger.warning(
        'Signup validation failed',
        tag: 'AUTH',
        data: {'reason': 'phone_too_short'},
      );
      throw const AuthFlowException('Enter a valid phone number.');
    }

    try {
      final authResponse = await authRepository.signUpWithEmail(
        fullName: fullName.trim(),
        username: username.trim(),
        email: email.trim(),
        password: password,
        phone: normalizedPhone,
      );

      final user = authResponse.user ?? authRepository.currentUser;
      if (user != null) {
        String? avatarUrl;
        if (avatarBytes != null && avatarBytes.isNotEmpty) {
          avatarUrl = await profileRepository.uploadAvatar(
            userId: user.id,
            bytes: avatarBytes,
          );
        }

        await profileRepository.upsertProfile({
          'user_id': user.id,
          'full_name': fullName.trim(),
          'username': username.trim(),
          if (avatarUrl != null && avatarUrl.isNotEmpty) 'avatar_url': avatarUrl,
        });
      }

      if (normalizedPhone != null) {
        await authRepository.sendOtp(emailOrPhone: normalizedPhone);
      }

      AppLogger.auth('Signup success', data: {'email': email.trim()});
    } on AppException catch (error) {
      AppLogger.error(
        'Signup failed',
        tag: 'AUTH',
        error: error,
        stackTrace: error.stackTrace,
      );
      throw AuthFlowException(error.message);
    } catch (error) {
      AppLogger.error('Signup failed', tag: 'AUTH', error: error);
      throw AuthFlowException(_fallbackMessage(error));
    }
  }

  String? _normalizePhone(String? value) {
    if (value == null) return null;

    final stripped = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    if (stripped.isEmpty) return null;
    return stripped;
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_looksLikeEmail(email)) {
      AppLogger.warning(
        'Password reset validation failed',
        tag: 'AUTH',
        data: {'reason': 'invalid_email'},
      );
      throw const AuthFlowException('Enter the email linked to your account.');
    }
    try {
      AppLogger.auth('Password reset started', data: {'email': email.trim()});
      await authRepository.sendPasswordReset(email.trim());
      AppLogger.auth('Password reset success', data: {'email': email.trim()});
    } on AppException catch (error) {
      AppLogger.error(
        'Password reset failed',
        tag: 'AUTH',
        error: error,
        stackTrace: error.stackTrace,
      );
      throw AuthFlowException(error.message);
    } catch (error) {
      AppLogger.error('Password reset failed', tag: 'AUTH', error: error);
      throw AuthFlowException(_fallbackMessage(error));
    }
  }

  Future<void> verifyOtp(String code, {String? emailOrPhone}) async {
    if (code.length != 6) {
      AppLogger.warning(
        'OTP validation failed',
        tag: 'AUTH',
        data: {'reason': 'length'},
      );
      throw const AuthFlowException('Enter the full 6-digit code.');
    }
    final target = emailOrPhone?.trim();
    if (target == null || target.isEmpty) {
      AppLogger.warning(
        'OTP verification skipped due to missing target',
        tag: 'AUTH',
      );
      return;
    }
    try {
      AppLogger.auth('OTP verification started', data: {'target': target});
      await authRepository.verifyOtp(emailOrPhone: target, token: code);
      AppLogger.auth('OTP verification success', data: {'target': target});
    } on AppException catch (error) {
      AppLogger.error(
        'OTP verification failed',
        tag: 'AUTH',
        error: error,
        stackTrace: error.stackTrace,
        data: {'target': target},
      );
      throw AuthFlowException(error.message);
    } catch (error) {
      AppLogger.error('OTP verification failed', tag: 'AUTH', error: error);
      throw AuthFlowException(_fallbackMessage(error));
    }
  }

  Future<void> resendOtp({required String emailOrPhone}) async {
    final target = emailOrPhone.trim();
    if (target.isEmpty) {
      AppLogger.warning(
        'OTP resend validation failed',
        tag: 'AUTH',
        data: {'reason': 'empty_target'},
      );
      throw const AuthFlowException('Add an email or phone to resend OTP.');
    }

    try {
      AppLogger.auth('OTP resend started', data: {'target': target});
      await authRepository.sendOtp(emailOrPhone: target);
      AppLogger.auth('OTP resend success', data: {'target': target});
    } on AppException catch (error) {
      AppLogger.error(
        'OTP resend failed',
        tag: 'AUTH',
        error: error,
        stackTrace: error.stackTrace,
      );
      throw AuthFlowException(error.message);
    } catch (error) {
      AppLogger.error('OTP resend failed', tag: 'AUTH', error: error);
      throw AuthFlowException(_fallbackMessage(error));
    }
  }

  Future<void> signOut() async {
    try {
      AppLogger.auth(
        'Logout started',
        data: {'source': 'AuthFlowController.signOut'},
      );
      await authRepository.signOut();
      AppLogger.auth(
        'Logout success',
        data: {'source': 'AuthFlowController.signOut'},
      );
    } on AppException catch (error) {
      AppLogger.error(
        'Logout failed',
        tag: 'AUTH',
        error: error,
        stackTrace: error.stackTrace,
      );
      throw AuthFlowException(error.message);
    } catch (error) {
      AppLogger.error('Logout failed', tag: 'AUTH', error: error);
      throw AuthFlowException(_fallbackMessage(error));
    }
  }

  bool _looksLikeEmail(String value) {
    final trimmed = value.trim();
    return trimmed.contains('@') && trimmed.contains('.');
  }

  String _fallbackMessage(Object error) {
    final text = error.toString().trim();
    if (text.isEmpty) return 'Authentication failed. Please try again.';
    final lower = text.toLowerCase();
    if (lower.startsWith('exception:')) {
      final cleaned = text.substring('exception:'.length).trim();
      return cleaned.isEmpty
          ? 'Authentication failed. Please try again.'
          : cleaned;
    }
    return text;
  }
}
