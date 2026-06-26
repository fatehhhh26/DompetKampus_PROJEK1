import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/bill_model.dart';
import '../models/financial_insight_model.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/financial_insight_service.dart';
import '../widgets/balance_card.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final transactions = context.watch<TransactionProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final billProvider = context.watch<BillProvider>();
    final latestTransactions = transactions.latestFilteredTransactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const AddTransactionScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Transaksi'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<TransactionProvider>().loadTransactions(),
              context.read<BudgetProvider>().loadBudgets(),
              context.read<BillProvider>().loadBills(),
            ]);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Halo, ${auth.name ?? 'Mahasiswa'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _MonthFilterHeader(provider: transactions),
                const SizedBox(height: 16),
                BalanceCard(
                  balance: transactions.filteredBalance,
                  income: transactions.filteredTotalIncome,
                  expense: transactions.filteredTotalExpense,
                ),
                const SizedBox(height: 16),
                _MonthlyInsightCard(
                  transactions: transactions.transactions,
                  budgetProvider: budgetProvider,
                ),
                const SizedBox(height: 16),
                _UpcomingBillsCard(provider: billProvider),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '5 transaksi terbaru',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AddTransactionScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Tambah'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (transactions.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (transactions.errorMessage != null)
                  EmptyStateWidget(
                    icon: Icons.wifi_off_rounded,
                    title: 'Gagal memuat transaksi',
                    message: transactions.errorMessage!,
                  )
                else if (latestTransactions.isEmpty)
                  const EmptyStateWidget(
                    icon: Icons.receipt_long_outlined,
                    title: 'Belum ada transaksi',
                    message:
                        'Mulai catat pemasukan atau pengeluaran pertamamu.',
                  )
                else
                  for (final transaction in latestTransactions)
                    TransactionCard(transaction: transaction),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MonthlyInsightCard extends StatelessWidget {
  const _MonthlyInsightCard({
    required this.transactions,
    required this.budgetProvider,
  });

  final List<TransactionModel> transactions;
  final BudgetProvider budgetProvider;
  static const _insightService = FinancialInsightService();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final insights = _insightService.generateSmartInsights(
      transactions: transactions,
      budgets: budgetProvider.budgets,
      month: DateTime(now.year, now.month),
      today: now,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: AppColors.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Insight Bulan Ini',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (insights.isEmpty)
              const Text(
                'Belum ada pengeluaran bulan ini. Mulai catat transaksi agar insight keuanganmu muncul di sini.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else
              for (var index = 0; index < insights.length; index++) ...[
                _SmartInsightTile(insight: insights[index]),
                if (index != insights.length - 1)
                  const Divider(height: 18, color: AppColors.border),
              ],
          ],
        ),
      ),
    );
  }
}

class _SmartInsightTile extends StatelessWidget {
  const _SmartInsightTile({required this.insight});

  final FinancialInsightModel insight;

  @override
  Widget build(BuildContext context) {
    final color = _colorForSeverity(insight.severity);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(_iconForType(insight.type), color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                insight.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                insight.message,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _colorForSeverity(String severity) {
    return switch (severity) {
      FinancialInsightModel.severityDanger => AppColors.expense,
      FinancialInsightModel.severityWarning => const Color(0xFFF59E0B),
      FinancialInsightModel.severitySuccess => AppColors.income,
      _ => AppColors.primary,
    };
  }

  IconData _iconForType(String type) {
    return switch (type) {
      FinancialInsightModel.typeBudget => Icons.account_balance_wallet_outlined,
      FinancialInsightModel.typeSaving => Icons.savings_outlined,
      FinancialInsightModel.typeSpending => Icons.trending_up_rounded,
      FinancialInsightModel.typeRecommendation =>
        Icons.health_and_safety_outlined,
      _ => Icons.auto_awesome_outlined,
    };
  }
}

class _UpcomingBillsCard extends StatelessWidget {
  const _UpcomingBillsCard({required this.provider});

  final BillProvider provider;

  @override
  Widget build(BuildContext context) {
    final upcomingBills = provider.getUpcomingBills(limit: 3);
    final overdueBills = provider.getOverdueBills();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  overdueBills.isEmpty
                      ? Icons.notifications_active_outlined
                      : Icons.warning_amber_rounded,
                  color: overdueBills.isEmpty
                      ? AppColors.primary
                      : AppColors.expense,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tagihan Terdekat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.isLoading)
              const Center(child: CircularProgressIndicator())
            else if (provider.errorMessage != null)
              Text(
                provider.errorMessage!,
                style: const TextStyle(color: AppColors.textSecondary),
              )
            else if (upcomingBills.isEmpty && overdueBills.isEmpty)
              const Text(
                'Belum ada tagihan aktif. Tambahkan tagihan agar pengingat jatuh tempo muncul di sini.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else ...[
              if (overdueBills.isNotEmpty) ...[
                Text(
                  '${overdueBills.length} tagihan lewat jatuh tempo. Segera cek dan tandai lunas jika sudah dibayar.',
                  style: const TextStyle(
                    color: AppColors.expense,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
              ],
              for (final bill in upcomingBills) _BillSummaryRow(bill: bill),
            ],
          ],
        ),
      ),
    );
  }
}

class _BillSummaryRow extends StatelessWidget {
  const _BillSummaryRow({required this.bill});

  final BillModel bill;

  @override
  Widget build(BuildContext context) {
    final dueDateLabel = DateFormat(
      'dd MMM yyyy',
      'id_ID',
    ).format(bill.dueDate);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.receipt_long_outlined, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bill.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  dueDateLabel,
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
          const SizedBox(width: 8),
          Text(
            CurrencyFormatter.format(bill.amount),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _MonthFilterHeader extends StatelessWidget {
  const _MonthFilterHeader({required this.provider});

  final TransactionProvider provider;

  @override
  Widget build(BuildContext context) {
    final selectedMonth = provider.selectedMonth;
    final label = selectedMonth == null
        ? 'Semua Data'
        : DateFormat('MMMM yyyy', 'id_ID').format(selectedMonth);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _pickMonth(context),
            icon: const Icon(Icons.calendar_month_outlined),
            label: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
        ),
        const SizedBox(width: 8),
        TextButton(
          onPressed: provider.isAllDataSelected ? null : provider.showAllData,
          child: const Text('Semua Data'),
        ),
      ],
    );
  }

  Future<void> _pickMonth(BuildContext context) async {
    final now = DateTime.now();
    final selectedMonth = provider.selectedMonth ?? now;
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 5),
      helpText: 'Pilih bulan transaksi',
    );

    if (pickedDate == null) return;
    provider.setMonthFilter(pickedDate);
  }
}
