import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../providers/budget_provider.dart';
import '../providers/transaction_provider.dart';
import '../widgets/app_feedback_dialog.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state_widget.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  static const _categories = [
    'Makanan',
    'Transportasi',
    'Kuliah',
    'Kos',
    'Internet',
    'Hiburan',
    'Lainnya',
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final budgetProvider = context.watch<BudgetProvider>();
    final transactionProvider = context.watch<TransactionProvider>();
    final budgets = budgetProvider.budgetsForMonth(now.month, now.year);

    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Budget'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await Future.wait([
              context.read<BudgetProvider>().loadBudgets(),
              context.read<TransactionProvider>().loadTransactions(),
            ]);
          },
          child: budgetProvider.isLoading
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 360,
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ],
                )
              : budgetProvider.errorMessage != null
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    EmptyStateWidget(
                      icon: Icons.wifi_off_rounded,
                      title: 'Gagal memuat budget',
                      message: budgetProvider.errorMessage!,
                    ),
                  ],
                )
              : budgets.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  children: [
                    EmptyStateWidget(
                      icon: Icons.account_balance_wallet_outlined,
                      title: 'Belum ada budget',
                      message:
                          'Buat batas pengeluaran bulanan untuk kategori penting.',
                    ),
                  ],
                )
              : ListView.builder(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: budgets.length,
                  itemBuilder: (context, index) {
                    return _BudgetCard(
                      budget: budgets[index],
                      transactions: transactionProvider.transactions,
                    );
                  },
                ),
        ),
      ),
    );
  }

  void _showBudgetSheet(BuildContext context, {BudgetModel? budget}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BudgetFormSheet(categories: _categories, budget: budget),
    );
  }
}

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({required this.budget, required this.transactions});

  final BudgetModel budget;
  final List<TransactionModel> transactions;

  @override
  Widget build(BuildContext context) {
    final budgetProvider = context.read<BudgetProvider>();
    final expense = budgetProvider.categoryExpense(
      category: budget.category,
      month: budget.month,
      year: budget.year,
      transactions: transactions,
    );
    final percent = budgetProvider.usagePercent(budget, transactions);
    final progress = (percent / 100).clamp(0.0, 1.0);
    final status = budgetProvider.statusFor(budget, transactions);
    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    budget.category,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusChip(label: _statusLabel(status), color: statusColor),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditSheet(context);
                    } else if (value == 'delete') {
                      _confirmDelete(context);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              DateFormat(
                'MMMM yyyy',
                'id_ID',
              ).format(DateTime(budget.year, budget.month)),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (budget.note.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                budget.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: statusColor,
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${percent.toStringAsFixed(1)}% terpakai',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${CurrencyFormatter.format(expense)} / ${CurrencyFormatter.format(budget.limitAmount)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEditSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BudgetFormSheet(
        categories: BudgetScreen._categories,
        budget: budget,
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus budget?'),
          content: const Text('Budget yang dihapus tidak bisa dikembalikan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !context.mounted) return;
    final provider = context.read<BudgetProvider>();
    final success = await provider.deleteBudget(budget.id);
    if (!context.mounted) return;

    if (!success) {
      await AppFeedbackDialog.showError(
        context,
        message: provider.errorMessage ?? 'Gagal menghapus budget.',
      );
    }
  }

  Color _statusColor(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.aman:
        return AppColors.secondary;
      case BudgetStatus.hampirHabis:
        return const Color(0xFFF59E0B);
      case BudgetStatus.terlampaui:
        return AppColors.expense;
    }
  }

  String _statusLabel(BudgetStatus status) {
    switch (status) {
      case BudgetStatus.aman:
        return 'Aman';
      case BudgetStatus.hampirHabis:
        return 'Hampir habis';
      case BudgetStatus.terlampaui:
        return 'Terlampaui';
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({required this.categories, this.budget});

  final List<String> categories;
  final BudgetModel? budget;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _limitController = TextEditingController();
  final _noteController = TextEditingController();

  late String _category;
  late int _month;
  late int _year;

  bool get _isEditMode => widget.budget != null;

  @override
  void initState() {
    super.initState();

    final now = DateTime.now();
    final budget = widget.budget;
    _category = budget?.category ?? widget.categories.first;
    _month = budget?.month ?? now.month;
    _year = budget?.year ?? now.year;
    _limitController.text = budget == null
        ? ''
        : budget.limitAmount.toStringAsFixed(0);
    _noteController.text = budget?.note ?? '';
  }

  @override
  void dispose() {
    _limitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _isEditMode ? 'Edit Budget' : 'Tambah Budget',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final category in widget.categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kategori wajib dipilih';
                  }
                  return null;
                },
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _category = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _limitController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal limit budget',
                  hintText: 'Contoh: 750000',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  if (value == null || value.trim().isEmpty) {
                    return 'Nominal wajib diisi';
                  }
                  if (amount <= 0) return 'Nominal harus lebih dari 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _month,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Bulan',
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                items: [
                  for (var month = 1; month <= 12; month++)
                    DropdownMenuItem(
                      value: month,
                      child: Text(
                        DateFormat(
                          'MMMM',
                          'id_ID',
                        ).format(DateTime(2024, month)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _month = value);
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _year,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Tahun',
                  prefixIcon: Icon(Icons.event_outlined),
                ),
                items: [
                  for (
                    var year = DateTime.now().year - 2;
                    year <= DateTime.now().year + 5;
                    year++
                  )
                    DropdownMenuItem(
                      value: year,
                      child: Text(
                        '$year',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _year = value);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Catatan',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_rounded),
                ),
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: _isEditMode ? 'Simpan Perubahan' : 'Simpan Budget',
                icon: Icons.save_rounded,
                onPressed: _saveBudget,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate()) return;
    if (_month < 1 || _month > 12 || _year < 2000) return;

    final budget = BudgetModel(
      id: widget.budget?.id ?? const Uuid().v4(),
      category: _category,
      month: _month,
      year: _year,
      limitAmount: _parseAmount(_limitController.text),
      note: _noteController.text.trim(),
      createdAt: widget.budget?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<BudgetProvider>();
    final bool success;
    if (_isEditMode) {
      success = await provider.updateBudget(budget);
    } else {
      success = await provider.addBudget(budget);
    }

    if (!mounted) return;
    if (!success) {
      await AppFeedbackDialog.showError(
        context,
        message: provider.errorMessage ?? 'Gagal menyimpan budget.',
      );
      return;
    }

    Navigator.of(context).pop();
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }
}
