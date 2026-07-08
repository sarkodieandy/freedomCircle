import 'package:supabase_flutter/supabase_flutter.dart' as sb;

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
      return client.auth.verifyOTP(
        email: isEmail ? emailOrPhone : null,
        phone: isEmail ? null : emailOrPhone,
        token: token,
        type: isEmail ? sb.OtpType.email : sb.OtpType.sms,
      );
    });
  }

  Future<void> sendPasswordReset(String email) {
    return guard(() => client.auth.resetPasswordForEmail(email));
  }

  Future<void> signOut() {
    return guard(() => client.auth.signOut());
  }
}
