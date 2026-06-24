import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/transaction_model.dart';
import '../services/remote_transaction_service.dart';

class TransactionProvider extends ChangeNotifier {
  TransactionProvider({RemoteTransactionService? remoteTransactionService})
    : _remoteTransactionService =
          remoteTransactionService ?? RemoteTransactionService() {
    loadTransactions();
  }

  final RemoteTransactionService _remoteTransactionService;
  final List<TransactionModel> _transactions = [];
  DateTime? _selectedMonth = DateTime(
    DateTime.now().year,
    DateTime.now().month,
  );
  bool _isLoading = false;
  String? _errorMessage;

  List<TransactionModel> get transactions => List.unmodifiable(_transactions);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  DateTime? get selectedMonth => _selectedMonth;
  bool get isAllDataSelected => _selectedMonth == null;

  List<TransactionModel> get latestTransactions =>
      List.unmodifiable(_transactions.take(5));

  List<TransactionModel> get filteredTransactions =>
      List.unmodifiable(_filterBySelectedMonth(_transactions));

  List<TransactionModel> get latestFilteredTransactions =>
      List.unmodifiable(filteredTransactions.take(5));

  double get totalIncome => _transactions
      .where((transaction) => transaction.type == TransactionModel.incomeType)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get totalExpense => _transactions
      .where((transaction) => transaction.type == TransactionModel.expenseType)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get balance => totalIncome - totalExpense;

  double get filteredTotalIncome => filteredTransactions
      .where((transaction) => transaction.type == TransactionModel.incomeType)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get filteredTotalExpense => filteredTransactions
      .where((transaction) => transaction.type == TransactionModel.expenseType)
      .fold(0, (total, transaction) => total + transaction.amount);

  double get filteredBalance => filteredTotalIncome - filteredTotalExpense;

  void setMonthFilter(DateTime month) {
    _selectedMonth = DateTime(month.year, month.month);
    notifyListeners();
  }

  void showAllData() {
    _selectedMonth = null;
    notifyListeners();
  }

  Future<void> loadTransactions() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteTransactions = await _remoteTransactionService
          .fetchTransactions();
      _transactions
        ..clear()
        ..addAll(remoteTransactions)
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (error, stackTrace) {
      debugPrint('Load remote transactions error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyError(error);
      _transactions.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    return _runMutation(
      actionName: 'addTransaction',
      action: () async {
        await _remoteTransactionService.addTransaction(transaction);
        await _reloadSilently();
      },
    );
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    return _runMutation(
      actionName: 'updateTransaction',
      action: () async {
        await _remoteTransactionService.updateTransaction(transaction);
        await _reloadSilently();
      },
    );
  }

  Future<bool> deleteTransaction(String id) async {
    return _runMutation(
      actionName: 'deleteTransaction',
      action: () async {
        await _remoteTransactionService.deleteTransaction(id);
        _transactions.removeWhere((transaction) => transaction.id == id);
      },
    );
  }

  void clear() {
    _transactions.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearTransactions() async => clear();

  Future<bool> _runMutation({
    required String actionName,
    required Future<void> Function() action,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } catch (error, stackTrace) {
      debugPrint('Remote transaction $actionName error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadSilently() async {
    final remoteTransactions = await _remoteTransactionService
        .fetchTransactions();
    _transactions
      ..clear()
      ..addAll(remoteTransactions)
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  List<TransactionModel> _filterBySelectedMonth(
    List<TransactionModel> transactions,
  ) {
    final selectedMonth = _selectedMonth;
    if (selectedMonth == null) return transactions;

    return transactions.where((transaction) {
      return transaction.date.year == selectedMonth.year &&
          transaction.date.month == selectedMonth.month;
    }).toList();
  }

  String _friendlyError(Object error) {
    if (error is StateError) return error.message;
    if (error is PostgrestException) {
      return 'Gagal memproses data transaksi. Silakan coba lagi.';
    }
    if (error is AuthException) {
      return 'Sesi login bermasalah. Silakan login ulang.';
    }

    final message = error.toString();
    if (message.toLowerCase().contains('socket') ||
        message.toLowerCase().contains('network') ||
        message.toLowerCase().contains('failed host lookup')) {
      return 'Koneksi internet bermasalah. Coba lagi nanti.';
    }

    return message;
  }
}
