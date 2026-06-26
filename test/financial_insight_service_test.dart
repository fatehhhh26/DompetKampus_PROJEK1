import 'package:dompet_kampus/models/budget_model.dart';
import 'package:dompet_kampus/models/financial_insight_model.dart';
import 'package:dompet_kampus/models/transaction_model.dart';
import 'package:dompet_kampus/services/financial_insight_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const service = FinancialInsightService();

  test('generates warning when a category spending increases sharply', () {
    final insights = service.generateSmartInsights(
      transactions: [
        _transaction(
          id: 'income',
          amount: 1500000,
          type: TransactionModel.incomeType,
          category: 'Beasiswa',
          date: DateTime(2026, 6, 1),
        ),
        _transaction(
          id: 'food-now',
          amount: 500000,
          category: 'Makan',
          date: DateTime(2026, 6, 10),
        ),
        _transaction(
          id: 'food-prev',
          amount: 250000,
          category: 'Makan',
          date: DateTime(2026, 5, 10),
        ),
      ],
      budgets: const [],
      month: DateTime(2026, 6),
      today: DateTime(2026, 6, 15),
    );

    expect(
      insights.any(
        (insight) =>
            insight.type == FinancialInsightModel.typeSpending &&
            insight.title.contains('Makan'),
      ),
      isTrue,
    );
  });

  test('generates danger insight when expenses exceed income', () {
    final insights = service.generateSmartInsights(
      transactions: [
        _transaction(
          id: 'income',
          amount: 500000,
          type: TransactionModel.incomeType,
          category: 'Uang bulanan',
          date: DateTime(2026, 6, 1),
        ),
        _transaction(
          id: 'expense',
          amount: 650000,
          category: 'Belanja',
          date: DateTime(2026, 6, 12),
        ),
      ],
      budgets: const [],
      month: DateTime(2026, 6),
      today: DateTime(2026, 6, 20),
    );

    expect(
      insights.any(
        (insight) =>
            insight.type == FinancialInsightModel.typeRecommendation &&
            insight.severity == FinancialInsightModel.severityDanger,
      ),
      isTrue,
    );
  });

  test('generates budget recommendation when budget is almost used up', () {
    final insights = service.generateSmartInsights(
      transactions: [
        _transaction(
          id: 'income',
          amount: 1200000,
          type: TransactionModel.incomeType,
          category: 'Beasiswa',
          date: DateTime(2026, 6, 1),
        ),
        _transaction(
          id: 'transport',
          amount: 80000,
          category: 'Transportasi',
          date: DateTime(2026, 6, 8),
        ),
      ],
      budgets: [
        BudgetModel(
          id: 'budget-transport',
          category: 'Transportasi',
          month: 6,
          year: 2026,
          limitAmount: 100000,
          note: '',
          createdAt: DateTime(2026, 6, 1),
        ),
      ],
      month: DateTime(2026, 6),
      today: DateTime(2026, 6, 10),
    );

    expect(
      insights.any(
        (insight) =>
            insight.type == FinancialInsightModel.typeBudget &&
            insight.severity == FinancialInsightModel.severityWarning,
      ),
      isTrue,
    );
  });
}

TransactionModel _transaction({
  required String id,
  required double amount,
  required String category,
  required DateTime date,
  String type = TransactionModel.expenseType,
}) {
  return TransactionModel(
    id: id,
    title: id,
    amount: amount,
    type: type,
    category: category,
    date: date,
    note: '',
  );
}
