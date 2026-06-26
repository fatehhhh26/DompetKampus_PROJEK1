import '../core/utils/currency_formatter.dart';
import '../models/budget_model.dart';
import '../models/financial_insight_model.dart';
import '../models/transaction_model.dart';

class FinancialInsightService {
  const FinancialInsightService();

  List<FinancialInsightModel> generateSmartInsights({
    required List<TransactionModel> transactions,
    required List<BudgetModel> budgets,
    DateTime? month,
    DateTime? today,
  }) {
    final referenceDate = today ?? DateTime.now();
    final selectedMonth =
        month ?? DateTime(referenceDate.year, referenceDate.month);
    final monthStart = DateTime(selectedMonth.year, selectedMonth.month);
    final previousMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
    final currentTransactions = _transactionsForMonth(transactions, monthStart);
    final previousTransactions = _transactionsForMonth(
      transactions,
      previousMonth,
    );
    final currentExpenses = currentTransactions.where((transaction) {
      return transaction.type == TransactionModel.expenseType;
    }).toList();
    final currentIncome = _sumByType(
      currentTransactions,
      TransactionModel.incomeType,
    );
    final currentExpense = _sumByType(
      currentTransactions,
      TransactionModel.expenseType,
    );

    if (currentTransactions.isEmpty) {
      return [
        FinancialInsightModel(
          id: 'empty-${monthStart.year}-${monthStart.month}',
          title: 'Insight belum tersedia',
          message:
              'Catat pemasukan dan pengeluaran bulan ini agar DompetKampus bisa membaca pola keuanganmu.',
          type: FinancialInsightModel.typeSummary,
          severity: FinancialInsightModel.severityInfo,
          createdAt: referenceDate,
        ),
      ];
    }

    final insights = <FinancialInsightModel>[
      _buildProjectionInsight(
        monthStart: monthStart,
        today: referenceDate,
        income: currentIncome,
        expense: currentExpense,
      ),
    ];

    final habitInsight = _buildSpendingHabitInsight(
      monthStart: monthStart,
      currentExpenses: currentExpenses,
      previousTransactions: previousTransactions,
      totalExpense: currentExpense,
      createdAt: referenceDate,
    );
    if (habitInsight != null) insights.add(habitInsight);

    final budgetInsight = _buildBudgetRecommendation(
      budgets: budgets,
      monthStart: monthStart,
      transactions: transactions,
      createdAt: referenceDate,
    );
    if (budgetInsight != null) insights.add(budgetInsight);

    final healthInsight = _buildFinancialHealthWarning(
      monthStart: monthStart,
      currentIncome: currentIncome,
      currentExpense: currentExpense,
      previousTransactions: previousTransactions,
      createdAt: referenceDate,
    );
    if (healthInsight != null) insights.add(healthInsight);

    final savingInsight = _buildSavingRecommendation(
      monthStart: monthStart,
      currentIncome: currentIncome,
      currentExpense: currentExpense,
      createdAt: referenceDate,
    );
    if (savingInsight != null) insights.add(savingInsight);

    return insights.take(5).toList(growable: false);
  }

  FinancialInsightModel _buildProjectionInsight({
    required DateTime monthStart,
    required DateTime today,
    required double income,
    required double expense,
  }) {
    final daysInMonth = DateTime(monthStart.year, monthStart.month + 1, 0).day;
    final isCurrentMonth =
        today.year == monthStart.year && today.month == monthStart.month;
    final elapsedDays = isCurrentMonth
        ? today.day.clamp(1, daysInMonth)
        : daysInMonth;
    final projectedExpense = (expense / elapsedDays) * daysInMonth;
    final projectedBalance = income - projectedExpense;
    final formattedBalance = CurrencyFormatter.format(projectedBalance.abs());

    if (income <= 0) {
      return FinancialInsightModel(
        id: 'projection-no-income-${monthStart.year}-${monthStart.month}',
        title: 'Pemasukan belum tercatat',
        message:
            'Pengeluaran bulan ini sudah ${CurrencyFormatter.format(expense)}. Catat pemasukan agar prediksi sisa uang lebih akurat.',
        type: FinancialInsightModel.typeSummary,
        severity: FinancialInsightModel.severityWarning,
        createdAt: today,
      );
    }

    if (projectedBalance < 0) {
      return FinancialInsightModel(
        id: 'projection-danger-${monthStart.year}-${monthStart.month}',
        title: 'Prediksi saldo akhir minus',
        message:
            'Dengan ritme saat ini, kamu berpotensi kurang sekitar $formattedBalance di akhir bulan.',
        type: FinancialInsightModel.typeSpending,
        severity: FinancialInsightModel.severityDanger,
        createdAt: today,
      );
    }

    return FinancialInsightModel(
      id: 'projection-safe-${monthStart.year}-${monthStart.month}',
      title: 'Prediksi sisa uang',
      message:
          'Jika ritme pengeluaran stabil, perkiraan sisa uang akhir bulan sekitar ${CurrencyFormatter.format(projectedBalance)}.',
      type: FinancialInsightModel.typeSummary,
      severity: projectedBalance < income * 0.15
          ? FinancialInsightModel.severityWarning
          : FinancialInsightModel.severitySuccess,
      createdAt: today,
    );
  }

  FinancialInsightModel? _buildSpendingHabitInsight({
    required DateTime monthStart,
    required List<TransactionModel> currentExpenses,
    required List<TransactionModel> previousTransactions,
    required double totalExpense,
    required DateTime createdAt,
  }) {
    if (currentExpenses.isEmpty || totalExpense <= 0) return null;

    final currentByCategory = _groupExpensesByCategory(currentExpenses);
    final previousByCategory = _groupExpensesByCategory(
      previousTransactions.where((transaction) {
        return transaction.type == TransactionModel.expenseType;
      }).toList(),
    );
    final biggest = currentByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = biggest.first;
    final previousAmount = previousByCategory[topCategory.key] ?? 0;
    final portion = topCategory.value / totalExpense;
    final increasedSharply =
        previousAmount > 0 && topCategory.value >= previousAmount * 1.3;

    if (increasedSharply) {
      final increase = topCategory.value - previousAmount;
      return FinancialInsightModel(
        id: 'habit-increase-${topCategory.key}-${monthStart.year}-${monthStart.month}',
        title: 'Pengeluaran ${topCategory.key} naik',
        message:
            'Kategori ini naik ${CurrencyFormatter.format(increase)} dibanding bulan lalu. Coba cek transaksi kecil yang sering berulang.',
        type: FinancialInsightModel.typeSpending,
        severity: FinancialInsightModel.severityWarning,
        createdAt: createdAt,
      );
    }

    if (portion >= 0.4 && topCategory.value >= 50000) {
      return FinancialInsightModel(
        id: 'habit-dominant-${topCategory.key}-${monthStart.year}-${monthStart.month}',
        title: '${topCategory.key} paling dominan',
        message:
            '${(portion * 100).toStringAsFixed(0)}% pengeluaran bulan ini ada di kategori ${topCategory.key}. Batasi kategori ini dulu kalau ingin cepat hemat.',
        type: FinancialInsightModel.typeSpending,
        severity: FinancialInsightModel.severityInfo,
        createdAt: createdAt,
      );
    }

    return null;
  }

  FinancialInsightModel? _buildBudgetRecommendation({
    required List<BudgetModel> budgets,
    required DateTime monthStart,
    required List<TransactionModel> transactions,
    required DateTime createdAt,
  }) {
    final monthlyBudgets = budgets.where((budget) {
      return budget.month == monthStart.month && budget.year == monthStart.year;
    }).toList();
    if (monthlyBudgets.isEmpty) return null;

    final sortedBudgets = monthlyBudgets
      ..sort((a, b) {
        final bUsage = _budgetUsage(b, transactions);
        final aUsage = _budgetUsage(a, transactions);
        return bUsage.compareTo(aUsage);
      });
    final budget = sortedBudgets.first;
    final usage = _budgetUsage(budget, transactions);
    final remaining =
        budget.limitAmount -
        _categoryExpense(
          category: budget.category,
          month: budget.month,
          year: budget.year,
          transactions: transactions,
        );

    if (usage >= 100) {
      return FinancialInsightModel(
        id: 'budget-over-${budget.id}',
        title: 'Budget ${budget.category} terlampaui',
        message:
            'Pengeluaran kategori ini sudah melewati batas. Untuk sisa bulan ini, prioritaskan kebutuhan wajib dulu.',
        type: FinancialInsightModel.typeBudget,
        severity: FinancialInsightModel.severityDanger,
        createdAt: createdAt,
      );
    }

    if (usage >= 75) {
      return FinancialInsightModel(
        id: 'budget-warning-${budget.id}',
        title: 'Budget ${budget.category} hampir habis',
        message:
            'Sisa budget sekitar ${CurrencyFormatter.format(remaining)}. Kurangi transaksi spontan di kategori ini.',
        type: FinancialInsightModel.typeBudget,
        severity: FinancialInsightModel.severityWarning,
        createdAt: createdAt,
      );
    }

    return FinancialInsightModel(
      id: 'budget-safe-${budget.id}',
      title: 'Budget masih terkendali',
      message:
          'Kategori ${budget.category} baru terpakai ${usage.toStringAsFixed(0)}%. Pertahankan ritme ini sampai akhir bulan.',
      type: FinancialInsightModel.typeBudget,
      severity: FinancialInsightModel.severitySuccess,
      createdAt: createdAt,
    );
  }

  FinancialInsightModel? _buildFinancialHealthWarning({
    required DateTime monthStart,
    required double currentIncome,
    required double currentExpense,
    required List<TransactionModel> previousTransactions,
    required DateTime createdAt,
  }) {
    if (currentIncome > 0) {
      final expenseRatio = currentExpense / currentIncome;
      if (expenseRatio >= 1) {
        return FinancialInsightModel(
          id: 'health-negative-${monthStart.year}-${monthStart.month}',
          title: 'Pengeluaran melewati pemasukan',
          message:
              'Pengeluaran sudah ${(expenseRatio * 100).toStringAsFixed(0)}% dari pemasukan. Ini tanda pola keuangan mulai tidak sehat.',
          type: FinancialInsightModel.typeRecommendation,
          severity: FinancialInsightModel.severityDanger,
          createdAt: createdAt,
        );
      }
      if (expenseRatio >= 0.85) {
        return FinancialInsightModel(
          id: 'health-tight-${monthStart.year}-${monthStart.month}',
          title: 'Ruang uang mulai sempit',
          message:
              'Pengeluaran sudah ${(expenseRatio * 100).toStringAsFixed(0)}% dari pemasukan. Sisihkan uang wajib sebelum menambah pengeluaran baru.',
          type: FinancialInsightModel.typeRecommendation,
          severity: FinancialInsightModel.severityWarning,
          createdAt: createdAt,
        );
      }
    }

    final previousExpense = _sumByType(
      previousTransactions,
      TransactionModel.expenseType,
    );
    if (previousExpense > 0 && currentExpense >= previousExpense * 1.35) {
      return FinancialInsightModel(
        id: 'health-trend-${monthStart.year}-${monthStart.month}',
        title: 'Pengeluaran melonjak',
        message:
            'Total pengeluaran naik dibanding bulan lalu. Review kategori terbesar sebelum akhir bulan.',
        type: FinancialInsightModel.typeRecommendation,
        severity: FinancialInsightModel.severityWarning,
        createdAt: createdAt,
      );
    }

    return null;
  }

  FinancialInsightModel? _buildSavingRecommendation({
    required DateTime monthStart,
    required double currentIncome,
    required double currentExpense,
    required DateTime createdAt,
  }) {
    if (currentIncome <= 0) return null;

    final remaining = currentIncome - currentExpense;
    if (remaining <= 0) return null;

    final recommendedSaving = remaining * 0.2;
    if (recommendedSaving < 10000) return null;

    return FinancialInsightModel(
      id: 'saving-recommendation-${monthStart.year}-${monthStart.month}',
      title: 'Rekomendasi hemat',
      message:
          'Coba simpan ${CurrencyFormatter.format(recommendedSaving)} dari sisa uang saat ini untuk target tabungan atau dana darurat.',
      type: FinancialInsightModel.typeSaving,
      severity: FinancialInsightModel.severityInfo,
      createdAt: createdAt,
    );
  }

  List<TransactionModel> _transactionsForMonth(
    List<TransactionModel> transactions,
    DateTime month,
  ) {
    return transactions.where((transaction) {
      return transaction.date.month == month.month &&
          transaction.date.year == month.year;
    }).toList();
  }

  Map<String, double> _groupExpensesByCategory(
    List<TransactionModel> expenses,
  ) {
    final grouped = <String, double>{};
    for (final transaction in expenses) {
      final category = transaction.category.trim().isEmpty
          ? 'Lainnya'
          : transaction.category.trim();
      grouped[category] = (grouped[category] ?? 0) + transaction.amount;
    }
    return grouped;
  }

  double _sumByType(List<TransactionModel> transactions, String type) {
    return transactions
        .where((transaction) => transaction.type == type)
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  double _budgetUsage(BudgetModel budget, List<TransactionModel> transactions) {
    if (budget.limitAmount <= 0) return 0;

    final expense = _categoryExpense(
      category: budget.category,
      month: budget.month,
      year: budget.year,
      transactions: transactions,
    );
    return (expense / budget.limitAmount) * 100;
  }

  double _categoryExpense({
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
}
