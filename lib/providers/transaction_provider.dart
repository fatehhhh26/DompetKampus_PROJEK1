import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/transaction_model.dart';
import '../services/local_storage_service.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider() {
    loadTransactions();
  }

  final List<TransactionModel> _transactions = [];

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);

  List<TransactionModel> get latestTransactions =>
      List.unmodifiable(_transactions.take(5));

  double get totalIncome => _transactions
      .where((transaction) => transaction.type == TransactionModel.incomeType)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get totalExpense => _transactions
      .where((transaction) => transaction.type == TransactionModel.expenseType)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get balance => totalIncome - totalExpense;

  void loadTransactions() {
    if (!Hive.isBoxOpen(LocalStorageService.transactionBox)) return;

    final box = Hive.box(LocalStorageService.transactionBox);
    _transactions
      ..clear()
      ..addAll(
        box.values
            .whereType<Map>()
            .map(TransactionModel.fromMap)
            .where((transaction) => transaction.id.isNotEmpty),
      )
      ..sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  Future<void> addTransaction(TransactionModel transaction) async {
    final box = Hive.box(LocalStorageService.transactionBox);
    await box.put(transaction.id, transaction.toMap());

    _transactions
      ..insert(0, transaction)
      ..sort((a, b) => b.date.compareTo(a.date));

    notifyListeners();
  }

  Future<void> updateTransaction(TransactionModel transaction) async {
    final box = Hive.box(LocalStorageService.transactionBox);
    await box.put(transaction.id, transaction.toMap());

    final index = _transactions.indexWhere(
      (currentTransaction) => currentTransaction.id == transaction.id,
    );

    if (index == -1) {
      _transactions.add(transaction);
    } else {
      _transactions[index] = transaction;
    }

    _transactions.sort((a, b) => b.date.compareTo(a.date));
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    final box = Hive.box(LocalStorageService.transactionBox);
    await box.delete(id);

    _transactions.removeWhere((transaction) => transaction.id == id);
    notifyListeners();
  }
}
