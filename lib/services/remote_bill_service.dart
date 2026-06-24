import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/bill_model.dart';

class RemoteBillService {
  SupabaseClient get _client => Supabase.instance.client;

  User get _currentUser {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('User belum login');
    }
    return user;
  }

  Future<List<BillModel>> fetchBills() async {
    final user = _currentUser;
    debugPrint('Fetching remote bills for user: ${user.id}');

    try {
      final response = await _client
          .from('bills')
          .select()
          .eq('user_id', user.id)
          .order('due_date', ascending: true);

      return response
          .map((item) => BillModel.fromJson(item))
          .where((bill) => bill.id.isNotEmpty)
          .toList();
    } on PostgrestException catch (error) {
      debugPrint('Supabase fetchBills error: ${error.message}');
      rethrow;
    }
  }

  Future<void> addBill(BillModel bill) async {
    final user = _currentUser;
    debugPrint('Adding remote bill: ${bill.id}');

    try {
      await _client.from('bills').insert({
        ...bill.toSupabaseMap(),
        'user_id': user.id,
      });
    } on PostgrestException catch (error) {
      debugPrint('Supabase addBill error: ${error.message}');
      rethrow;
    }
  }

  Future<void> updateBill(BillModel bill) async {
    final user = _currentUser;
    debugPrint('Updating remote bill: ${bill.id}');

    try {
      await _client
          .from('bills')
          .update({
            ...bill.toSupabaseMap(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', bill.id)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      debugPrint('Supabase updateBill error: ${error.message}');
      rethrow;
    }
  }

  Future<void> deleteBill(String id) async {
    final user = _currentUser;
    debugPrint('Deleting remote bill: $id');

    try {
      await _client.from('bills').delete().eq('id', id).eq('user_id', user.id);
    } on PostgrestException catch (error) {
      debugPrint('Supabase deleteBill error: ${error.message}');
      rethrow;
    }
  }

  Future<void> markBillAsPaid(String id) async {
    await _setPaidStatus(id: id, isPaid: true);
  }

  Future<void> markBillAsUnpaid(String id) async {
    await _setPaidStatus(id: id, isPaid: false);
  }

  Future<void> _setPaidStatus({
    required String id,
    required bool isPaid,
  }) async {
    final user = _currentUser;
    debugPrint('Updating remote bill paid status: $id -> $isPaid');

    try {
      await _client
          .from('bills')
          .update({
            'is_paid': isPaid,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', id)
          .eq('user_id', user.id);
    } on PostgrestException catch (error) {
      debugPrint('Supabase update bill paid status error: ${error.message}');
      rethrow;
    }
  }
}
