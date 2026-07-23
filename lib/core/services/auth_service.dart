import '../supabase/supabase_config.dart';

class AuthService {
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return AuthResult.success(response.user?.id);
    } on Exception catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  static Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await SupabaseConfig.auth.signUp(
        email: email,
        password: password,
        data: {'name': name},
      );

      if (response.user != null) {
        try {
          await SupabaseConfig.client.from('users').upsert({
            'id': response.user!.id,
            'name': name,
            'email': email,
          });
        } catch (_) {
          // Trigger já pode ter criado o registro
        }
      }

      return AuthResult.success(response.user?.id);
    } on Exception catch (e) {
      return AuthResult.failure(e.toString());
    }
  }

  static Future<void> signOut() async {
    await SupabaseConfig.auth.signOut();
  }

  static Future<void> resetPassword(String email) async {
    await SupabaseConfig.auth.resetPasswordForEmail(email);
  }
}

class AuthResult {
  final bool isSuccess;
  final String? userId;
  final String? error;

  AuthResult._({required this.isSuccess, this.userId, this.error});

  factory AuthResult.success(String? userId) {
    return AuthResult._(isSuccess: true, userId: userId);
  }

  factory AuthResult.failure(String error) {
    return AuthResult._(isSuccess: false, error: error);
  }
}
