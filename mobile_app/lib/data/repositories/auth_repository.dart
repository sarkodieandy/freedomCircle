import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../core/errors/app_exception.dart' show AuthException;
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
    return guard(
      () => client.auth.signInWithPassword(email: email, password: password),
    );
  }

  Future<sb.AuthResponse> signUpWithEmail({
    required String fullName,
    required String username,
    required String email,
    required String password,
    String? phone,
  }) {
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
    );
  }

  Future<sb.AuthResponse> verifyOtp({
    required String emailOrPhone,
    required String token,
  }) {
    return guard(() {
      final isEmail = emailOrPhone.contains('@');
      if (!isEmail) {
        return _verifyPhoneOtp(emailOrPhone, token);
      }
      return client.auth.verifyOTP(
        email: isEmail ? emailOrPhone : null,
        phone: isEmail ? null : emailOrPhone,
        token: token,
        type: isEmail ? sb.OtpType.email : sb.OtpType.sms,
      );
    });
  }

  Future<void> sendOtp({required String emailOrPhone}) {
    return guard(() async {
      final isEmail = emailOrPhone.contains('@');
      if (isEmail) {
        await client.auth.resend(type: sb.OtpType.signup, email: emailOrPhone);
        return;
      }

      await _invokeOtpFunction('send', {
        'phone': emailOrPhone,
        'purpose': 'auth_login',
        'user_id': currentUser?.id,
      });
    });
  }

  Future<void> sendPasswordReset(String email) {
    return guard(() => client.auth.resetPasswordForEmail(email));
  }

  Future<void> signOut() {
    return guard(() => client.auth.signOut());
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
    final response = await client.functions.invoke(
      'africastalking-otp',
      body: {'action': action, ...payload},
    );

    final data = response.data;
    final decoded = data is Map<String, dynamic>
        ? data
        : <String, dynamic>{'message': data?.toString()};

    if (response.status < 200 || response.status >= 300) {
      throw AuthException(
        decoded['message']?.toString() ??
            'OTP request failed with status ${response.status}.',
      );
    }

    if (decoded['verified'] == false) {
      throw AuthException(
        decoded['message']?.toString() ?? 'OTP verification failed.',
      );
    }

    return decoded;
  }
}
