import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart' show AuthException;
import '../../core/utils/app_logger.dart';
import 'supabase_repository.dart';

class AuthRepository extends SupabaseRepository {
  const AuthRepository({super.supabaseClient});

  sb.User? get currentUser => client.auth.currentUser;

  sb.Session? get currentSession => client.auth.currentSession;

  Stream<sb.AuthState> authStateChanges() => client.auth.onAuthStateChange;

  Stream<sb.AuthState> listenToAuthChanges() => authStateChanges();

  sb.User? getCurrentUser() => currentUser;

  Future<sb.AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    AppLogger.auth(
      'Supabase login started',
      data: {'source': 'AuthRepository.signInWithEmail', 'email': email},
    );
    return guard(
      () => client.auth.signInWithPassword(email: email, password: password),
      source: 'AuthRepository.signInWithEmail',
    );
  }

  Future<sb.AuthResponse> signUpWithEmail({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? phone,
  }) {
    AppLogger.auth(
      'Supabase signup started',
      data: {
        'source': 'AuthRepository.signUpWithEmail',
        'email': email,
        'phone_present': phone?.isNotEmpty == true,
      },
    );
    return guard(
      () => client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'username': username,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      ),
      source: 'AuthRepository.signUpWithEmail',
    );
  }

  Future<sb.AuthResponse> verifyOtp({
    required String emailOrPhone,
    required String token,
  }) {
    final target = emailOrPhone.trim();
    final isEmail = target.contains('@');
    final normalizedTarget = isEmail ? target : _normalizePhoneInput(target);

    AppLogger.auth(
      'OTP verification started',
      data: {'source': 'AuthRepository.verifyOtp', 'target': normalizedTarget},
    );
    return guard(() {
      if (!isEmail) {
        return _verifyPhoneOtp(normalizedTarget, token);
      }
      return client.auth.verifyOTP(
        email: isEmail ? normalizedTarget : null,
        phone: isEmail ? null : normalizedTarget,
        token: token,
        type: isEmail ? sb.OtpType.email : sb.OtpType.sms,
      );
    }, source: 'AuthRepository.verifyOtp');
  }

  Future<void> sendOtp({required String emailOrPhone}) {
    return guard(() async {
      final target = emailOrPhone.trim();
      final isEmail = target.contains('@');
      final normalizedTarget = isEmail ? target : _normalizePhoneInput(target);

      AppLogger.auth(
        'OTP resend started',
        data: {'source': 'AuthRepository.sendOtp', 'target': normalizedTarget},
      );
      if (isEmail) {
        await client.auth.resend(
          type: sb.OtpType.signup,
          email: normalizedTarget,
        );
        return;
      }

      await _invokeOtpFunction('send', {
        'phone': normalizedTarget,
        'purpose': 'auth_login',
        'user_id': currentUser?.id,
      });
    }, source: 'AuthRepository.sendOtp');
  }

  Future<void> sendPasswordReset(String email) {
    AppLogger.auth(
      'Password reset started',
      data: {'source': 'AuthRepository.sendPasswordReset', 'email': email},
    );
    return guard(
      () => client.auth.resetPasswordForEmail(email),
      source: 'AuthRepository.sendPasswordReset',
    );
  }

  Future<void> signOut() {
    AppLogger.auth(
      'Supabase logout started',
      data: {'source': 'AuthRepository.signOut'},
    );
    return guard(() => client.auth.signOut(), source: 'AuthRepository.signOut');
  }

  Future<sb.AuthResponse> _verifyPhoneOtp(String phone, String token) async {
    await _invokeOtpFunction('verify', {
      'phone': phone,
      'code': token,
      'purpose': 'auth_login',
      'user_id': currentUser?.id,
    });

    final session = currentSession;
    final user = currentUser;
    return sb.AuthResponse(session: session, user: user);
  }

  Future<Map<String, dynamic>> _invokeOtpFunction(
    String action,
    Map<String, dynamic> payload,
  ) async {
    AppLogger.supabase(
      'OTP edge function invoke started',
      table: 'africastalking-otp',
      data: {'action': action},
    );
    final response = await client.functions.invoke(
      'africastalking-otp',
      body: {'action': action, ...payload},
    );

    final data = response.data;
    final decoded = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'message': data?.toString()};

    if (response.status < 200 || response.status >= 300) {
      AppLogger.error(
        'OTP edge function invoke failed',
        tag: 'AUTH',
        data: {'status': response.status, 'action': action},
      );
      throw AuthException(
        decoded['message']?.toString() ??
            'OTP request failed with status ${response.status}.',
        source: 'AuthRepository._invokeOtpFunction',
      );
    }

    if (decoded['verified'] == false) {
      AppLogger.warning(
        'OTP verification response rejected',
        tag: 'AUTH',
        data: {'action': action},
      );
      throw AuthException(
        decoded['message']?.toString() ?? 'OTP verification failed.',
        source: 'AuthRepository._invokeOtpFunction',
      );
    }

    AppLogger.auth(
      'OTP edge function invoke success',
      data: {'action': action, 'status': response.status},
    );

    return decoded;
  }

  String _normalizePhoneInput(String phone) {
    final normalized = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    return normalized;
  }
}
