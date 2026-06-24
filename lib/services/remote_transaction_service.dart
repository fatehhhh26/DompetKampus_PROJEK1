import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';

class RemoteTransactionService {
  SupabaseClient get _client => Supabase.instance.client;

  User get _currentUser {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum login');
    }
    return user;
  }

  Future<List<TransactionModel>> fetchTransactions() async {
    final user = _currentUser;
    debugPrint('Fetching remote transactions for user: ${user.id}');

    final response = await _client
        .from('transactions')
        .select()
        .eq('user_id', user.id)
        .order('date', ascending: false);

    return response
        .map((item) => TransactionModel.fromJson(item))
        .where((transaction) => transaction.id.isNotEmpty)
        .toList();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final user = _currentUser;
    debugPrint('Adding remote transaction: ${transaction.id}');

    await _client.from('transactions').insert({
      ...transaction.toSupabaseMap(),
      'user_id': user.id,
    });
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final user = _currentUser;
    debugPrint('Updating remote transaction: ${transaction.id}');

    await _client
        .from('transactions')
        .update({
          ...transaction.toSupabaseMap(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transaction.id)
        .eq('user_id', user.id);
  }

  Future<void> deleteTransaction(String id) async {
    final user = _currentUser;
    debugPrint('Deleting remote transaction: $id');

    await _client
        .from('transactions')
        .delete()
        .eq('id', id)
        .eq('user_id', user.id);
  }
}
