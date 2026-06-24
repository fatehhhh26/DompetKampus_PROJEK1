import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/saving_goal_model.dart';
import '../services/remote_saving_goal_service.dart';

class SavingGoalProvider extends ChangeNotifier {
  SavingGoalProvider({RemoteSavingGoalService? remoteSavingGoalService})
    : _remoteSavingGoalService =
          remoteSavingGoalService ?? RemoteSavingGoalService() {
    loadSavingGoals();
  }

  final RemoteSavingGoalService _remoteSavingGoalService;
  final List<SavingGoalModel> _goals = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<SavingGoalModel> get goals => List.unmodifiable(_goals);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadGoals() => loadSavingGoals();

  Future<void> loadSavingGoals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final remoteGoals = await _remoteSavingGoalService.fetchSavingGoals();
      _goals
        ..clear()
        ..addAll(remoteGoals);
    } catch (error, stackTrace) {
      debugPrint('Load remote saving goals error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyError(error);
      _goals.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addGoal(SavingGoalModel goal) => addSavingGoal(goal);

  Future<bool> addSavingGoal(SavingGoalModel goal) {
    return _runMutation(
      actionName: 'addSavingGoal',
      action: () async {
        await _remoteSavingGoalService.addSavingGoal(goal.copyWith());
        await _reloadSilently();
      },
    );
  }

  Future<bool> updateSavingGoal(SavingGoalModel goal) {
    return _runMutation(
      actionName: 'updateSavingGoal',
      action: () async {
        await _remoteSavingGoalService.updateSavingGoal(goal.copyWith());
        await _reloadSilently();
      },
    );
  }

  Future<bool> deleteGoal(String id) => deleteSavingGoal(id);

  Future<bool> deleteSavingGoal(String id) {
    return _runMutation(
      actionName: 'deleteSavingGoal',
      action: () async {
        await _remoteSavingGoalService.deleteSavingGoal(id);
        _goals.removeWhere((goal) => goal.id == id);
      },
    );
  }

  Future<bool> clearGoals() async {
    return _runMutation(
      actionName: 'clearSavingGoals',
      action: () async {
        final goalsToDelete = _goals.isEmpty
            ? await _remoteSavingGoalService.fetchSavingGoals()
            : List<SavingGoalModel>.from(_goals);

        for (final goal in goalsToDelete) {
          await _remoteSavingGoalService.deleteSavingGoal(goal.id);
        }

        _goals.clear();
      },
    );
  }

  void clear() {
    _goals.clear();
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateCurrentAmount(String id, double additionalAmount) {
    return addAmountToGoal(id, additionalAmount);
  }

  Future<bool> addAmountToGoal(String id, double additionalAmount) async {
    if (additionalAmount <= 0) return false;

    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index == -1) {
      _errorMessage = 'Target tabungan tidak ditemukan.';
      notifyListeners();
      return false;
    }

    final currentGoal = _goals[index];
    final updatedGoal = currentGoal.copyWith(
      currentAmount: currentGoal.currentAmount + additionalAmount,
    );

    return updateSavingGoal(updatedGoal);
  }

  double progressPercent(SavingGoalModel goal) => goal.progress * 100;

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
      debugPrint('Remote saving goal $actionName error: $error');
      debugPrintStack(stackTrace: stackTrace);
      _errorMessage = _friendlyError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _reloadSilently() async {
    final remoteGoals = await _remoteSavingGoalService.fetchSavingGoals();
    _goals
      ..clear()
      ..addAll(remoteGoals);
  }

  String _friendlyError(Object error) {
    if (error is StateError) return error.message;
    if (error is PostgrestException) {
      return 'Gagal memproses data target tabungan. Silakan coba lagi.';
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
