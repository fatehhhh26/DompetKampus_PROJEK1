import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  SupabaseClient get _client => Supabase.instance.client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<AuthResponse> register({
    required String name,
    required String email,
    required String password,
  }) async {
    debugPrint('Supabase register started for email: $email');
    final response = await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );

    final user = response.user;
    if (user != null) {
      debugPrint(
        'Supabase register auth success, inserting profile: ${user.id}',
      );
      await _client.from('profiles').upsert({
        'id': user.id,
        'name': name,
        'email': email,
      }, onConflict: 'id');
      debugPrint('Supabase profile upsert success: ${user.id}');
    }

    return response;
  }

  Future<AuthResponse> login({
    required String email,
    required String password,
  }) {
    debugPrint('Supabase login started for email: $email');
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> logout() {
    return _client.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    final profile = await _client
        .from('profiles')
        .select()
        .eq('id', userId)
        .maybeSingle();

    return profile;
  }

  Future<Map<String, dynamic>> updateProfile({
    required String userId,
    required String name,
    required String email,
  }) async {
    await _client.auth.updateUser(UserAttributes(data: {'name': name}));

    final profile = await _client
        .from('profiles')
        .upsert({'id': userId, 'name': name, 'email': email}, onConflict: 'id')
        .select()
        .single();

    return profile;
  }
}
