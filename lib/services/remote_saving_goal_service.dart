import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/saving_goal_model.dart';

class RemoteSavingGoalService {
  SupabaseClient get _client => Supabase.instance.client;

  User get _currentUser {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum login');
    }
    return user;
  }

  Future<List<SavingGoalModel>> fetchSavingGoals() async {
    final user = _currentUser;
    debugPrint('Fetching remote saving goals for user: ${user.id}');

    final response = await _client
        .from('saving_goals')
        .select()
        .eq('user_id', user.id)
        .order('created_at', ascending: false);

    return response
        .map((item) => SavingGoalModel.fromJson(item))
        .where((goal) => goal.id.isNotEmpty)
        .toList();
  }

  Future<void> addSavingGoal(SavingGoalModel goal) async {
    final user = _currentUser;
    debugPrint('Adding remote saving goal: ${goal.id}');

    await _client.from('saving_goals').insert({
      ...goal.copyWith().toSupabaseMap(),
      'user_id': user.id,
    });
  }

  Future<void> updateSavingGoal(SavingGoalModel goal) async {
    final user = _currentUser;
    debugPrint('Updating remote saving goal: ${goal.id}');

    await _client
        .from('saving_goals')
        .update({
          ...goal.copyWith().toSupabaseMap(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', goal.id)
        .eq('user_id', user.id);
  }

  Future<void> deleteSavingGoal(String id) async {
    final user = _currentUser;
    debugPrint('Deleting remote saving goal: $id');

    await _client
        .from('saving_goals')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }
}
