import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/app_feedback_dialog.dart';
import '../widgets/custom_button.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    this.transaction,
    this.initialType,
    this.initialTitle,
    this.initialAmount,
    this.initialCategory,
    this.initialNote,
    this.initialDate,
  });

  final TransactionModel? transaction;
  final String? initialType;
  final String? initialTitle;
  final double? initialAmount;
  final String? initialCategory;
  final String? initialNote;
  final DateTime? initialDate;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  static const _incomeCategories = [
    'Uang Saku',
    'Beasiswa',
    'Kerja Part-time',
    'Hadiah',
    'Lainnya',
  ];

  static const _expenseCategories = [
    'Makanan',
    'Belanja',
    'Transportasi',
    'Print/Tugas',
    'Kuliah',
    'Kos',
    'Internet',
    'Hiburan',
    'Lainnya',
  ];

  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _type = TransactionModel.expenseType;
  String _category = _expenseCategories.first;
  DateTime _selectedDate = DateTime.now();

  bool get _isEditMode => widget.transaction != null;

  List<String> get _categories => _type == TransactionModel.incomeType
      ? _incomeCategories
      : _expenseCategories;

  @override
  void initState() {
    super.initState();

    final transaction = widget.transaction;
    if (transaction == null) {
      _titleController.text = widget.initialTitle ?? '';
      _amountController.text = widget.initialAmount == null
          ? ''
          : widget.initialAmount!.toStringAsFixed(0);
      _noteController.text = widget.initialNote ?? '';
      _type = widget.initialType == TransactionModel.incomeType
          ? TransactionModel.incomeType
          : TransactionModel.expenseType;
      _category = _normalizeCategory(
        widget.initialCategory ?? _categories.first,
      );
      _selectedDate = widget.initialDate ?? DateTime.now();
      return;
    }

    _titleController.text = transaction.title;
    _amountController.text = transaction.amount.toStringAsFixed(0);
    _noteController.text = transaction.note;
    _type = transaction.type;
    _category = _normalizeCategory(transaction.category);
    _selectedDate = transaction.date;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? 'Edit Transaksi' : 'Tambah Transaksi'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                _isEditMode ? 'Ubah transaksi' : 'Catat transaksi baru',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                _isEditMode
                    ? 'Perbarui detail transaksi yang sudah tercatat.'
                    : 'Simpan pemasukan dan pengeluaran kampusmu di sini.',
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Judul transaksi',
                  prefixIcon: Icon(Icons.edit_note),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Judul transaksi wajib diisi';
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
                  hintText: 'Contoh: 25000',
                  prefixIcon: Icon(Icons.payments_outlined),
                ),
                validator: (value) {
                  final amount = _parseAmount(value ?? '');
                  if (value == null || value.trim().isEmpty) {
                    return 'Nominal wajib diisi';
                  }
                  if (amount <= 0) {
                    return 'Nominal harus lebih dari 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(
                  labelText: 'Jenis transaksi',
                  prefixIcon: Icon(Icons.swap_vert_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                    value: TransactionModel.incomeType,
                    child: Text('Pemasukan'),
                  ),
                  DropdownMenuItem(
                    value: TransactionModel.expenseType,
                    child: Text('Pengeluaran'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _type = value;
                    _category = _categories.first;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: ValueKey(_type),
                initialValue: _category,
                decoration: const InputDecoration(
                  labelText: 'Kategori',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                items: [
                  for (final category in _categories)
                    DropdownMenuItem(value: category, child: Text(category)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setState(() => _category = value);
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
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Tanggal'),
                subtitle: Text(
                  DateFormat(
                    'EEEE, dd MMMM yyyy',
                    'id_ID',
                  ).format(_selectedDate),
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: _pickDate,
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: _isEditMode ? 'Simpan Perubahan' : 'Simpan',
                icon: Icons.save_rounded,
                onPressed: _saveTransaction,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate == null) return;
    setState(() => _selectedDate = pickedDate);
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final transaction = TransactionModel(
      id: widget.transaction?.id ?? const Uuid().v4(),
      title: _titleController.text.trim(),
      amount: _parseAmount(_amountController.text),
      type: _type,
      category: _category,
      date: _selectedDate,
      note: _noteController.text.trim(),
    );

    final provider = context.read<TransactionProvider>();
    final bool success;
    if (_isEditMode) {
      success = await provider.updateTransaction(transaction);
    } else {
      success = await provider.addTransaction(transaction);
    }

    if (!mounted) return;

    if (!success) {
      await AppFeedbackDialog.showError(
        context,
        message: provider.errorMessage ?? 'Gagal menyimpan transaksi.',
      );
      return;
    }

    Navigator.of(context).pop(_isEditMode);
  }

  double _parseAmount(String value) {
    final normalized = value.replaceAll('.', '').replaceAll(',', '.').trim();
    return double.tryParse(normalized) ?? 0;
  }

  String _normalizeCategory(String category) {
    if (_categories.contains(category)) return category;
    return _categories.first;
  }
}
