import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/bill_model.dart';
import '../providers/bill_provider.dart';
import '../widgets/custom_button.dart';
import '../widgets/empty_state_widget.dart';

enum _BillFilter { all, unpaid, paid, overdue }

class BillScreen extends StatefulWidget {
  const BillScreen({super.key});

  static const categories = [
    'Kos',
    'Listrik',
    'Internet',
    'Kuliah',
    'Transportasi',
    'Langganan',
    'Lainnya',
  ];

  @override
  State<BillScreen> createState() => _BillScreenState();
}

class _BillScreenState extends State<BillScreen> {
  _BillFilter _filter = _BillFilter.all;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BillProvider>();
    final bills = _filteredBills(provider.bills);

    return Scaffold(
      appBar: AppBar(title: const Text('Tagihan')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBillSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Tagihan'),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => context.read<BillProvider>().loadBills(),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16),
            children: [
              _FilterChips(
                selectedFilter: _filter,
                onChanged: (filter) => setState(() => _filter = filter),
              ),
              const SizedBox(height: 16),
              if (provider.isLoading)
                const SizedBox(
                  height: 360,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (provider.errorMessage != null)
                EmptyStateWidget(
                  icon: Icons.wifi_off_rounded,
                  title: 'Gagal memuat tagihan',
                  message: provider.errorMessage!,
                )
              else if (bills.isEmpty)
                EmptyStateWidget(
                  icon: Icons.notifications_active_outlined,
                  title: _emptyTitle,
                  message:
                      'Tambahkan tagihan kos, internet, UKT, atau langganan agar tidak kelewat jatuh tempo.',
                )
              else
                for (final bill in bills)
                  _BillCard(
                    bill: bill,
                    onEdit: () => _showBillSheet(context, bill: bill),
                    onDelete: () => _confirmDelete(context, bill),
                    onTogglePaid: () => _togglePaid(context, bill),
                  ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  String get _emptyTitle {
    switch (_filter) {
      case _BillFilter.all:
        return 'Belum ada tagihan';
      case _BillFilter.unpaid:
        return 'Tidak ada tagihan belum lunas';
      case _BillFilter.paid:
        return 'Belum ada tagihan lunas';
      case _BillFilter.overdue:
        return 'Tidak ada tagihan jatuh tempo';
    }
  }

  List<BillModel> _filteredBills(List<BillModel> bills) {
    switch (_filter) {
      case _BillFilter.all:
        return bills;
      case _BillFilter.unpaid:
        return bills.where((bill) => !bill.isPaid).toList();
      case _BillFilter.paid:
        return bills.where((bill) => bill.isPaid).toList();
      case _BillFilter.overdue:
        return bills.where((bill) => bill.isOverdue).toList();
    }
  }

  void _showBillSheet(BuildContext context, {BillModel? bill}) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _BillFormSheet(bill: bill),
    );
  }

  Future<void> _confirmDelete(BuildContext context, BillModel bill) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus tagihan?'),
          content: Text('Tagihan ${bill.title} akan dihapus permanen.'),
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

    final provider = context.read<BillProvider>();
    final success = await provider.deleteBill(bill.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Tagihan berhasil dihapus.'
              : provider.errorMessage ?? 'Gagal menghapus tagihan.',
        ),
      ),
    );
  }

  Future<void> _togglePaid(BuildContext context, BillModel bill) async {
    final provider = context.read<BillProvider>();
    final success = bill.isPaid
        ? await provider.markAsUnpaid(bill.id)
        : await provider.markAsPaid(bill.id);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? bill.isPaid
                    ? 'Tagihan ditandai belum lunas.'
                    : 'Tagihan ditandai lunas.'
              : provider.errorMessage ?? 'Gagal memperbarui tagihan.',
        ),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({required this.selectedFilter, required this.onChanged});

  final _BillFilter selectedFilter;
  final ValueChanged<_BillFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _FilterChipItem(
            label: 'Semua',
            filter: _BillFilter.all,
            selectedFilter: selectedFilter,
            onChanged: onChanged,
          ),
          _FilterChipItem(
            label: 'Belum lunas',
            filter: _BillFilter.unpaid,
            selectedFilter: selectedFilter,
            onChanged: onChanged,
          ),
          _FilterChipItem(
            label: 'Lunas',
            filter: _BillFilter.paid,
            selectedFilter: selectedFilter,
            onChanged: onChanged,
          ),
          _FilterChipItem(
            label: 'Jatuh tempo',
            filter: _BillFilter.overdue,
            selectedFilter: selectedFilter,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _FilterChipItem extends StatelessWidget {
  const _FilterChipItem({
    required this.label,
    required this.filter,
    required this.selectedFilter,
    required this.onChanged,
  });

  final String label;
  final _BillFilter filter;
  final _BillFilter selectedFilter;
  final ValueChanged<_BillFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selectedFilter == filter,
        onSelected: (_) => onChanged(filter),
      ),
    );
  }
}

class _BillCard extends StatelessWidget {
  const _BillCard({
    required this.bill,
    required this.onEdit,
    required this.onDelete,
    required this.onTogglePaid,
  });

  final BillModel bill;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTogglePaid;

  @override
  Widget build(BuildContext context) {
    final statusColor = bill.isPaid
        ? AppColors.secondary
        : bill.isOverdue
        ? AppColors.expense
        : AppColors.primary;
    final dueDateLabel = DateFormat(
      'dd MMMM yyyy',
      'id_ID',
    ).format(bill.dueDate);

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
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        CurrencyFormatter.format(bill.amount),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                _StatusChip(label: _statusLabel, color: statusColor),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') onEdit();
                    if (value == 'delete') onDelete();
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoRow(
              icon: Icons.category_outlined,
              label: bill.category,
              color: AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.event_outlined,
              label: 'Jatuh tempo $dueDateLabel',
              color: bill.isOverdue
                  ? AppColors.expense
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              icon: Icons.notifications_active_outlined,
              label: 'Pengingat ${bill.reminderDaysBefore} hari sebelumnya',
              color: AppColors.textSecondary,
            ),
            if (bill.note.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                bill.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onTogglePaid,
                icon: Icon(
                  bill.isPaid
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                ),
                label: Text(
                  bill.isPaid ? 'Tandai belum lunas' : 'Tandai lunas',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _statusLabel {
    if (bill.isPaid) return 'Lunas';
    if (bill.isOverdue) return 'Lewat tempo';
    return 'Belum lunas';
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: color),
          ),
        ),
      ],
    );
  }
}

class _BillFormSheet extends StatefulWidget {
  const _BillFormSheet({this.bill});

  final BillModel? bill;

  @override
  State<_BillFormSheet> createState() => _BillFormSheetState();
}

class _BillFormSheetState extends State<_BillFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _reminderController = TextEditingController(text: '1');

  late String _category;
  DateTime? _dueDate;

  bool get _isEditMode => widget.bill != null;

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    _category = bill?.category ?? BillScreen.categories.first;
    _titleController.text = bill?.title ?? '';
    _amountController.text = bill == null ? '' : bill.amount.toStringAsFixed(0);
    _noteController.text = bill?.note ?? '';
    _reminderController.text = (bill?.reminderDaysBefore ?? 1).toString();
    _dueDate = bill?.dueDate;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _reminderController.dispose();
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
                _isEditMode ? 'Edit Tagihan' : 'Tambah Tagihan',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nama tagihan',
                  prefixIcon: Icon(Icons.receipt_long_outlined),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Nama tagihan wajib diisi';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Nominal',
                  hintText: 'Contoh: 250000',
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
              DropdownButtonFormField<String>(
                initialValue: _category,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final category in BillScreen.categories)
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
                controller: _reminderController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Pengingat hari sebelum jatuh tempo',
                  prefixIcon: Icon(Icons.notifications_active_outlined),
                ),
                validator: (value) {
                  final days = int.tryParse(value ?? '') ?? -1;
                  if (days < 0) return 'Pengingat minimal 0 hari';
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
                  if (_dueDate == null) {
                    return 'Tanggal jatuh tempo wajib dipilih';
                  }
                  return null;
                },
                builder: (field) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.event_outlined),
                        title: const Text('Tanggal jatuh tempo'),
                        subtitle: Text(
                          _dueDate == null
                              ? 'Pilih tanggal'
                              : DateFormat(
                                  'EEEE, dd MMMM yyyy',
                                  'id_ID',
                                ).format(_dueDate!),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () async {
                          await _pickDueDate();
                          field.didChange(_dueDate);
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
                label: _isEditMode ? 'Simpan Perubahan' : 'Simpan Tagihan',
                icon: Icons.save_rounded,
                onPressed: _saveBill,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: now.add(const Duration(days: 3650)),
    );

    if (pickedDate == null) return;
    setState(() => _dueDate = pickedDate);
  }

  Future<void> _saveBill() async {
    if (!_formKey.currentState!.validate() || _dueDate == null) return;

    final bill = BillModel(
      id: widget.bill?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: _parseAmount(_amountController.text),
      dueDate: _dueDate!,
      category: _category,
      note: _noteController.text.trim(),
      isPaid: widget.bill?.isPaid ?? false,
      reminderDaysBefore: int.tryParse(_reminderController.text) ?? 1,
      createdAt: widget.bill?.createdAt ?? DateTime.now(),
    );

    final provider = context.read<BillProvider>();
    final success = _isEditMode
        ? await provider.updateBill(bill)
        : await provider.addBill(bill);

    if (!mounted) return;
    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Gagal menyimpan tagihan.'),
        ),
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
