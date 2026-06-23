import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';

import '../models/saving_goal_model.dart';
import '../services/local_storage_service.dart';

class SavingGoalProvider extends ChangeNotifier {
  SavingGoalProvider() {
    loadGoals();
  }

  final List<SavingGoalModel> _goals = [];

  List<SavingGoalModel> get goals => List.unmodifiable(_goals);

  void loadGoals() {
    if (!Hive.isBoxOpen(LocalStorageService.savingGoalBox)) return;

    final box = Hive.box(LocalStorageService.savingGoalBox);
    _goals
      ..clear()
      ..addAll(
        box.values
            .whereType<Map>()
            .map(SavingGoalModel.fromMap)
            .where((goal) => goal.id.isNotEmpty),
      )
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    notifyListeners();
  }

  Future<void> addGoal(SavingGoalModel goal) async {
    final normalizedGoal = goal.copyWith();
    final box = Hive.box(LocalStorageService.savingGoalBox);
    await box.put(normalizedGoal.id, normalizedGoal.toMap());

    _goals
      ..add(normalizedGoal)
      ..sort((a, b) => a.deadline.compareTo(b.deadline));

    notifyListeners();
  }

  Future<void> deleteGoal(String id) async {
    final box = Hive.box(LocalStorageService.savingGoalBox);
    await box.delete(id);

    _goals.removeWhere((goal) => goal.id == id);
    notifyListeners();
  }

  Future<void> updateCurrentAmount(String id, double additionalAmount) async {
    if (additionalAmount <= 0) return;

    final index = _goals.indexWhere((goal) => goal.id == id);
    if (index == -1) return;

    final currentGoal = _goals[index];
    final updatedGoal = currentGoal.copyWith(
      currentAmount: currentGoal.currentAmount + additionalAmount,
    );

    final box = Hive.box(LocalStorageService.savingGoalBox);
    await box.put(updatedGoal.id, updatedGoal.toMap());

    _goals[index] = updatedGoal;
    _goals.sort((a, b) => a.deadline.compareTo(b.deadline));
    notifyListeners();
  }

  double progressPercent(SavingGoalModel goal) => goal.progress * 100;
}
