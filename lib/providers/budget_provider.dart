import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../services/remote_budget_service.dart';

enum BudgetStatus { aman, hampirHabis, terlampaui }

class BudgetProvider extends ChangeNotifier {
  BudgetProvider({RemoteBudgetService? remoteBudgetService})
    : _remoteBudgetService = remoteBudgetService ?? RemoteBudgetService() {
    loadBudgets();
  }

  final RemoteBudgetService _remoteBudgetService;
  final List<BudgetModel> _budgets = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<BudgetModel> get budgets => List.unmodifiable(_budgets);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadBudgets() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteBudgets = await _remoteBudgetService.fetchBudgets();
      _budgets
        ..clear()
        ..addAll(remoteBudgets);
    } catch (error, stackTrace) {
      debugPrint('Load remote budgets error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyError(error);
      _budgets.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  List<BudgetModel> getBudgetsByMonth(int month, int year) {
    return budgetsForMonth(month, year);
  }

  List<BudgetModel> budgetsForMonth(int month, int year) {
    final filteredBudgets =
        _budgets
            .where((budget) => budget.month == month && budget.year == year)
            .toList()
          ..sort((a, b) => a.category.compareTo(b.category));

    return List.unmodifiable(filteredBudgets);
  }

  Future<bool> addBudget(BudgetModel budget) {
    return _runMutation(
      actionName: 'addBudget',
      action: () async {
        await _remoteBudgetService.addBudget(budget);
        await _reloadSilently();
      },
    );
  }

  Future<bool> updateBudget(BudgetModel budget) {
    return _runMutation(
      actionName: 'updateBudget',
      action: () async {
        await _remoteBudgetService.updateBudget(budget);
        await _reloadSilently();
      },
    );
  }

  Future<bool> deleteBudget(String id) {
    return _runMutation(
      actionName: 'deleteBudget',
      action: () async {
        await _remoteBudgetService.deleteBudget(id);
        _budgets.removeWhere((budget) => budget.id == id);
      },
    );
  }

  Future<bool> clearBudgets() {
    return _runMutation(
      actionName: 'clearBudgets',
      action: () async {
        final budgetsToDelete = _budgets.isEmpty
            ? await _remoteBudgetService.fetchBudgets()
            : List<BudgetModel>.from(_budgets);

        for (final budget in budgetsToDelete) {
          await _remoteBudgetService.deleteBudget(budget.id);
        }

        _budgets.clear();
      },
    );
  }

  void clear() {
    _budgets.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  double getExpenseForCategory({
    required String category,
    required int month,
    required int year,
    required List<TransactionModel> transactions,
  }) {
    return categoryExpense(
      category: category,
      month: month,
      year: year,
      transactions: transactions,
    );
  }

  double categoryExpense({
    required String category,
    required int month,
    required int year,
    required List<TransactionModel> transactions,
  }) {
    return transactions
        .where(
          (transaction) =>
              transaction.type == TransactionModel.expenseType &&
              transaction.category == category &&
              transaction.date.month == month &&
              transaction.date.year == year,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  double getBudgetUsagePercentage(
    BudgetModel budget,
    List<TransactionModel> transactions,
  ) {
    return usagePercent(budget, transactions);
  }

  double usagePercent(BudgetModel budget, List<TransactionModel> transactions) {
    if (budget.limitAmount <= 0) return 0;

    final expense = categoryExpense(
      category: budget.category,
      month: budget.month,
      year: budget.year,
      transactions: transactions,
    );

    return (expense / budget.limitAmount) * 100;
  }

  BudgetStatus getBudgetStatus(
    BudgetModel budget,
    List<TransactionModel> transactions,
  ) {
    return statusFor(budget, transactions);
  }

  BudgetStatus statusFor(
    BudgetModel budget,
    List<TransactionModel> transactions,
  ) {
    final percent = usagePercent(budget, transactions);
    if (percent >= 100) return BudgetStatus.terlampaui;
    if (percent >= 75) return BudgetStatus.hampirHabis;
    return BudgetStatus.aman;
  }

  BudgetModel? getMostCriticalBudget({
    required int month,
    required int year,
    required List<TransactionModel> transactions,
  }) {
    final budgets = budgetsForMonth(month, year);
    if (budgets.isEmpty) return null;

    final sortedBudgets = [...budgets]
      ..sort((a, b) {
        final bUsage = usagePercent(b, transactions);
        final aUsage = usagePercent(a, transactions);
        return bUsage.compareTo(aUsage);
      });

    return sortedBudgets.first;
  }

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
      debugPrint('Remote budget $actionName error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadSilently() async {
    final remoteBudgets = await _remoteBudgetService.fetchBudgets();
    _budgets
      ..clear()
      ..addAll(remoteBudgets);
  }

  String _friendlyError(Object error) {
    if (error is StateError) return error.message;
    if (error is PostgrestException) {
      return 'Gagal memproses data budget. Silakan coba lagi.';
    }
    if (error is AuthException) {
      return 'Sesi login bermasalah. Silakan login ulang.';
    }

    final message = error.toString();
    final lowerMessage = message.toLowerCase();
    if (lowerMessage.contains('socket') ||
        lowerMessage.contains('network') ||
        lowerMessage.contains('failed host lookup')) {
      return 'Koneksi internet bermasalah. Coba lagi nanti.';
    }

    return message;
  }
}
