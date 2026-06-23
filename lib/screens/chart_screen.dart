import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/empty_state_widget.dart';

class ChartScreen extends StatelessWidget {
  const ChartScreen({super.key});

  static const _chartColors = [
    Color(0xFF2563EB),
    Color(0xFF10B981),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF14B8A6),
    Color(0xFFEC4899),
    Color(0xFF64748B),
  ];

  @override
  Widget build(BuildContext context) {
    final transactions = context.watch<TransactionProvider>().transactions;
    final expenseByCategory = _groupExpensesByCategory(transactions);
    final totalExpense = expenseByCategory.values.fold<double>(
      0,
      (total, amount) => total + amount,
    );

    if (expenseByCategory.isEmpty || totalExpense <= 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Grafik')),
        body: const SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: EmptyStateWidget(
              icon: Icons.pie_chart_outline,
              title: 'Belum ada pengeluaran',
              message:
                  'Grafik kategori akan muncul setelah kamu mencatat pengeluaran.',
            ),
          ),
        ),
      );
    }

    final entries = expenseByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final biggestCategory = entries.first;

    return Scaffold(
      appBar: AppBar(title: const Text('Grafik')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SummaryGrid(
                totalExpense: totalExpense,
                biggestCategory: biggestCategory.key,
                activeCategoryCount: entries.length,
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengeluaran per kategori',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 260,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 3,
                            centerSpaceRadius: 58,
                            startDegreeOffset: -90,
                            sections: [
                              for (
                                var index = 0;
                                index < entries.length;
                                index++
                              )
                                _buildSection(
                                  entry: entries[index],
                                  totalExpense: totalExpense,
                                  color:
                                      _chartColors[index % _chartColors.length],
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var index = 0; index < entries.length; index++)
                        _CategoryLegendTile(
                          category: entries[index].key,
                          amount: entries[index].value,
                          totalExpense: totalExpense,
                          color: _chartColors[index % _chartColors.length],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, double> _groupExpensesByCategory(
    List<TransactionModel> transactions,
  ) {
    final grouped = <String, double>{};

    for (final transaction in transactions) {
      if (transaction.type != TransactionModel.expenseType) continue;

      final category = transaction.category.trim().isEmpty
          ? 'Lainnya'
          : transaction.category.trim();
      grouped[category] = (grouped[category] ?? 0) + transaction.amount;
    }

    return grouped;
  }

  PieChartSectionData _buildSection({
    required MapEntry<String, double> entry,
    required double totalExpense,
    required Color color,
  }) {
    final percentage = totalExpense == 0
        ? 0
        : (entry.value / totalExpense) * 100;
    final showTitle = percentage >= 8;

    return PieChartSectionData(
      value: entry.value,
      color: color,
      radius: 86,
      title: showTitle ? '${percentage.toStringAsFixed(0)}%' : '',
      titleStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({
    required this.totalExpense,
    required this.biggestCategory,
    required this.activeCategoryCount,
  });

  final double totalExpense;
  final String biggestCategory;
  final int activeCategoryCount;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.35,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      children: [
        _SummaryCard(
          label: 'Total pengeluaran',
          value: CurrencyFormatter.format(totalExpense),
          icon: Icons.payments_outlined,
          color: AppColors.expense,
        ),
        _SummaryCard(
          label: 'Kategori terbesar',
          value: biggestCategory,
          icon: Icons.trending_up_rounded,
          color: AppColors.primary,
        ),
        _SummaryCard(
          label: 'Kategori aktif',
          value: '$activeCategoryCount kategori',
          icon: Icons.category_outlined,
          color: AppColors.secondary,
        ),
        const _SummaryCard(
          label: 'Tipe data',
          value: 'Pengeluaran',
          icon: Icons.pie_chart_outline_rounded,
          color: Color(0xFFF59E0B),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const Spacer(),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryLegendTile extends StatelessWidget {
  const _CategoryLegendTile({
    required this.category,
    required this.amount,
    required this.totalExpense,
    required this.color,
  });

  final String category;
  final double amount;
  final double totalExpense;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final percentage = totalExpense == 0 ? 0 : (amount / totalExpense) * 100;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: percentage / 100,
                  color: color,
                  backgroundColor: AppColors.border,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(99),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
