import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/saving_goal_model.dart';
import '../providers/saving_goal_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state_widget.dart';

class SavingGoalScreen extends StatelessWidget {
  const SavingGoalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final goals = context.watch<SavingGoalProvider>().goals;

    return Scaffold(
      appBar: AppBar(title: const Text('Tabungan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddGoalSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Target'),
      ),
      body: SafeArea(
        child: goals.isEmpty
            ? const SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: EmptyStateWidget(
                  icon: Icons.savings_outlined,
                  title: 'Belum ada target',
                  message:
                      'Buat target tabungan untuk laptop, kos, atau kebutuhan kuliah.',
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: goals.length,
                itemBuilder: (context, index) {
                  return _SavingGoalCard(goal: goals[index]);
                },
              ),
      ),
    );
  }

  void _showAddGoalSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _AddGoalSheet(),
    );
  }
}

class _SavingGoalCard extends StatelessWidget {
  const _SavingGoalCard({required this.goal});

  final SavingGoalModel goal;

  @override
  Widget build(BuildContext context) {
    final remainingAmount = (goal.targetAmount - goal.currentAmount).clamp(
      0,
      goal.targetAmount,
    );
    final progressColor = goal.isCompleted
        ? AppColors.secondary
        : AppColors.primary;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              goal.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (goal.isCompleted)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondary.withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: const Text(
                                'Tercapai',
                                style: TextStyle(
                                  color: AppColors.secondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Deadline ${DateFormat('dd MMMM yyyy', 'id_ID').format(goal.deadline)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Hapus target',
                  onPressed: () => _confirmDelete(context, goal.id),
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
              ],
            ),
            if (goal.note.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                goal.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: goal.progress,
                color: progressColor,
                backgroundColor: AppColors.border,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${goal.progressPercent}% terkumpul',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Sisa ${CurrencyFormatter.format(remainingAmount.toDouble())}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _AmountInfo(
                    label: 'Terkumpul',
                    value: CurrencyFormatter.format(goal.currentAmount),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AmountInfo(
                    label: 'Target',
                    value: CurrencyFormatter.format(goal.targetAmount),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: goal.isCompleted
                    ? null
                    : () => _showAddAmountDialog(context, goal),
                icon: const Icon(Icons.add_card_rounded),
                label: const Text('Tambah nominal'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus target?'),
          content: const Text(
            'Target tabungan yang dihapus tidak bisa dikembalikan.',
          ),
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
    await context.read<SavingGoalProvider>().deleteGoal(id);
  }

  void _showAddAmountDialog(BuildContext context, SavingGoalModel goal) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddAmountDialog(goal: goal),
    );
  }
}

class _AmountInfo extends StatelessWidget {
  const _AmountInfo({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
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
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  const _AddGoalSheet();

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime? _deadline;

  @override
  void dispose() {
    _titleController.dispose();
    _targetAmountController.dispose();
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
                'Tambah target tabungan',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nama target',
                  prefixIcon: Icon(Icons.flag_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama target wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal target',
                  hintText: 'Contoh: 8000000',
                  prefixIcon: Icon(Icons.savings_outlined),
                ),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  if (value == null || value.trim().isEmpty) {
                    return 'Nominal target wajib diisi';
                  }
                  if (amount <= 0) return 'Nominal target harus lebih dari 0';
                  return null;
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
              const SizedBox(height: 16),
              FormField<DateTime>(
                validator: (_) {
                  if (_deadline == null) return 'Deadline wajib dipilih';
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_month_outlined),
                        title: const Text('Deadline'),
                        subtitle: Text(
                          _deadline == null
                              ? 'Pilih tanggal deadline'
                              : DateFormat(
                                  'EEEE, dd MMMM yyyy',
                                  'id_ID',
                                ).format(_deadline!),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          await _pickDeadline();
                          field.didChange(_deadline);
                        },
                      ),
                      if (field.hasError)
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: Text(
                            field.errorText!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: 'Simpan target',
                icon: Icons.save_rounded,
                onPressed: _saveGoal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDeadline() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _deadline ?? now.add(const Duration(days: 30)),
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (pickedDate == null) return;
    setState(() => _deadline = pickedDate);
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate() || _deadline == null) return;

    await context.read<SavingGoalProvider>().addGoal(
      SavingGoalModel(
        id: const Uuid().v4(),
        title: _titleController.text.trim(),
        targetAmount: _parseAmount(_targetAmountController.text),
        currentAmount: 0,
        deadline: _deadline!,
        note: _noteController.text.trim(),
        isCompleted: false,
      ),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }
}

class _AddAmountDialog extends StatefulWidget {
  const _AddAmountDialog({required this.goal});

  final SavingGoalModel goal;

  @override
  State<_AddAmountDialog> createState() => _AddAmountDialogState();
}

class _AddAmountDialogState extends State<_AddAmountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Tambah nominal ${widget.goal.title}'),
      content: Form(
        key: _formKey,
        child: TextFormField(
          controller: _amountController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Nominal tambahan',
            hintText: 'Contoh: 50000',
            prefixIcon: Icon(Icons.add_card_rounded),
          ),
          validator: (value) {
            final amount = _parseAmount(value ?? '');
            if (value == null || value.trim().isEmpty) {
              return 'Nominal tambahan wajib diisi';
            }
            if (amount <= 0) return 'Nominal harus lebih dari 0';
            return null;
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _saveAmount, child: const Text('Tambah')),
      ],
    );
  }

  Future<void> _saveAmount() async {
    if (!_formKey.currentState!.validate()) return;

    await context.read<SavingGoalProvider>().updateCurrentAmount(
      widget.goal.id,
      _parseAmount(_amountController.text),
    );

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }
}
