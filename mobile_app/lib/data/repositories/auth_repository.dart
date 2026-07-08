import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_repository.dart';

class AuthRepository extends SupabaseRepository {
  const AuthRepository({super.supabaseClient});

  User? get currentUser => client.auth.currentUser;

  Session? get currentSession => client.auth.currentSession;

  Stream<AuthState> authStateChanges() => client.auth.onAuthStateChange;

  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) {
    return guard(
      () => client.auth.signInWithPassword(email: email, password: password),
    );
  }

  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? fullName,
  }) {
    return guard(
      () => client.auth.signUp(
        email: email,
        password: password,
        data: fullName == null ? null : {'full_name': fullName},
      ),
    );
  }

  Future<void> sendPasswordReset(String email) {
    return guard(() => client.auth.resetPasswordForEmail(email));
  }

  Future<void> signOut() {
    return guard(() => client.auth.signOut());
  }
}
