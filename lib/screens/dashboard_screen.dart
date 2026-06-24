import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../providers/auth_provider.dart';
import '../providers/bill_provider.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
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

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentMonthTransactions = transactions.where((transaction) {
      return transaction.date.month == now.month &&
          transaction.date.year == now.year;
    }).toList();
    final currentMonthExpenses = currentMonthTransactions
        .where(
          (transaction) => transaction.type == TransactionModel.expenseType,
        )
        .toList();
    final totalExpense = currentMonthExpenses.fold<double>(
      0,
      (total, transaction) => total + transaction.amount,
    );
    final biggestCategory = _biggestExpenseCategory(currentMonthExpenses);
    final criticalBudget = budgetProvider.getMostCriticalBudget(
      month: now.month,
      year: now.year,
      transactions: transactions,
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
            if (currentMonthExpenses.isEmpty)
              const Text(
                'Belum ada pengeluaran bulan ini. Mulai catat transaksi agar insight keuanganmu muncul di sini.',
                style: TextStyle(color: AppColors.textSecondary),
              )
            else ...[
              _InsightRow(
                label: 'Kategori terbesar',
                value: biggestCategory ?? '-',
              ),
              _InsightRow(
                label: 'Total pengeluaran',
                value: CurrencyFormatter.format(totalExpense),
              ),
              _InsightRow(
                label: 'Budget paling kritis',
                value: criticalBudget == null
                    ? 'Belum ada budget'
                    : criticalBudget.category,
              ),
              const SizedBox(height: 8),
              Text(
                _messageFor(totalExpense, criticalBudget),
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String? _biggestExpenseCategory(List<TransactionModel> expenses) {
    final grouped = <String, double>{};
    for (final transaction in expenses) {
      grouped[transaction.category] =
          (grouped[transaction.category] ?? 0) + transaction.amount;
    }

    if (grouped.isEmpty) return null;
    final entries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries.first.key;
  }

  String _messageFor(double totalExpense, BudgetModel? criticalBudget) {
    if (criticalBudget == null) {
      return 'Tambahkan budget bulanan agar pengeluaranmu lebih mudah dikontrol.';
    }

    final usage = budgetProvider.usagePercent(criticalBudget, transactions);
    if (usage >= 100) {
      return 'Budget ${criticalBudget.category} sudah terlampaui. Coba tahan pengeluaran di kategori ini.';
    }
    if (usage >= 75) {
      return 'Budget ${criticalBudget.category} hampir habis. Masih bisa dikendalikan dengan sedikit rem.';
    }

    return 'Kondisi bulan ini masih aman. Pertahankan ritme pengeluaranmu.';
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

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
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
