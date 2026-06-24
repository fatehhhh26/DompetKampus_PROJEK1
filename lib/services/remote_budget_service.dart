import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/budget_model.dart';

class RemoteBudgetService {
  SupabaseClient get _client => Supabase.instance.client;

  User get _currentUser {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum login');
    }
    return user;
  }

  Future<List<BudgetModel>> fetchBudgets() async {
    final user = _currentUser;
    debugPrint('Fetching remote budgets for user: ${user.id}');

    try {
      final response = await _client
          .from('budgets')
          .select()
          .eq('user_id', user.id)
          .order('year', ascending: false)
          .order('month', ascending: false)
          .order('created_at', ascending: false);

      return response
          .map((item) => BudgetModel.fromJson(item))
          .where((budget) => budget.id.isNotEmpty)
          .toList();
    } on PostgrestException catch (error) {
      debugPrint('Supabase fetchBudgets error: ${error.message}');
      rethrow;
    }
  }

  Future<void> addBudget(BudgetModel budget) async {
    final user = _currentUser;
    debugPrint('Adding remote budget: ${budget.id}');

    try {
      await _client.from('budgets').insert({
        ...budget.toSupabaseMap(),
        'user_id': user.id,
      });
    } on PostgrestException catch (error) {
      debugPrint('Supabase addBudget error: ${error.message}');
      rethrow;
    }
  }

  Future<void> updateBudget(BudgetModel budget) async {
    final user = _currentUser;
    debugPrint('Updating remote budget: ${budget.id}');

    try {
      await _client
          .from('budgets')
          .update({
            ...budget.toSupabaseMap(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', budget.id)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      debugPrint('Supabase updateBudget error: ${error.message}');
      rethrow;
    }
  }

  Future<void> deleteBudget(String id) async {
    final user = _currentUser;
    debugPrint('Deleting remote budget: $id');

    try {
      await _client
          .from('budgets')
          .delete()
          .eq('id', id)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      debugPrint('Supabase deleteBudget error: ${error.message}');
      rethrow;
    }
  }
}
