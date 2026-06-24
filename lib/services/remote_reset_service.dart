import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RemoteResetService {
  SupabaseClient get _client => Supabase.instance.client;

  User get _currentUser {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum login');
    }
    return user;
  }

  Future<void> resetAllUserData() async {
    final user = _currentUser;

    try {
      await _client.from('transactions').delete().eq('user_id', user.id);
      await _client.from('saving_goals').delete().eq('user_id', user.id);
      await _client.from('budgets').delete().eq('user_id', user.id);
    } on PostgrestException catch (error, stackTrace) {
      debugPrint('Supabase resetAllUserData error: ${error.message}');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      debugPrint('Reset all user data error: $error');
      debugPrintStack(stackTrace: stackTrace);
      rethrow;
    }
  }
}
