import 'package:hive/hive.dart';

class LocalStorageService {
  static const String settingsBox = 'settings';
  static const String transactionBox = 'transactions';
  static const String savingGoalBox = 'saving_goals';
  static const String budgetBox = 'budgets';

  static Future<void> init() async {
    await Hive.openBox(settingsBox);
    await Hive.openBox(transactionBox);
    await Hive.openBox(savingGoalBox);
    await Hive.openBox(budgetBox);
  }
}
