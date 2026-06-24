import 'dart:io';

import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../core/utils/currency_formatter.dart';
import '../models/bill_model.dart';
import '../models/budget_model.dart';
import '../models/saving_goal_model.dart';
import '../models/transaction_model.dart';

class ExcelService {
  Future<void> exportTransactionsToExcel(
    List<TransactionModel> transactions,
  ) async {
    await exportFullReportToExcel(
      transactions: transactions,
      savingGoals: const [],
      budgets: const [],
      bills: const [],
    );
  }

  Future<void> exportSavingGoalsToExcel(List<SavingGoalModel> goals) async {
    await exportFullReportToExcel(
      transactions: const [],
      savingGoals: goals,
      budgets: const [],
      bills: const [],
    );
  }

  Future<void> exportBudgetsToExcel(
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
  ) async {
    await exportFullReportToExcel(
      transactions: transactions,
      savingGoals: const [],
      budgets: budgets,
      bills: const [],
    );
  }

  Future<void> exportBillsToExcel(List<BillModel> bills) async {
    await exportFullReportToExcel(
      transactions: const [],
      savingGoals: const [],
      budgets: const [],
      bills: bills,
    );
  }

  Future<void> exportFullReportToExcel({
    required List<TransactionModel> transactions,
    required List<SavingGoalModel> savingGoals,
    required List<BudgetModel> budgets,
    required List<BillModel> bills,
  }) async {
    final excel = Excel.createExcel();
    excel.rename('Sheet1', 'Ringkasan');

    _buildSummarySheet(excel, transactions, savingGoals, budgets, bills);
    _buildTransactionSheet(excel, transactions);
    _buildSavingGoalSheet(excel, savingGoals);
    _buildBudgetSheet(excel, budgets, transactions);
    _buildBillSheet(excel, bills);

    final fileBytes = excel.save();
    if (fileBytes == null) {
      throw StateError('Gagal membuat file Excel.');
    }

    final directory = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
    final file = File('${directory.path}/DompetKampus_Report_$timestamp.xlsx');
    await file.writeAsBytes(fileBytes, flush: true);

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: 'Laporan Excel DompetKampus',
      ),
    );
  }

  void _buildSummarySheet(
    Excel excel,
    List<TransactionModel> transactions,
    List<SavingGoalModel> savingGoals,
    List<BudgetModel> budgets,
    List<BillModel> bills,
  ) {
    final sheet = excel['Ringkasan'];
    final totalIncome = transactions
        .where((transaction) => transaction.isIncome)
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final totalExpense = transactions
        .where((transaction) => transaction.isExpense)
        .fold<double>(0, (total, transaction) => total + transaction.amount);
    final unpaidBills = bills.where((bill) => !bill.isPaid).length;
    final overdueBills = bills.where((bill) => bill.isOverdue).length;

    _appendRow(sheet, ['Item', 'Nilai']);
    _appendRow(sheet, ['Tanggal export', _dateTime(DateTime.now())]);
    _appendRow(sheet, [
      'Total pemasukan',
      CurrencyFormatter.format(totalIncome),
    ]);
    _appendRow(sheet, [
      'Total pengeluaran',
      CurrencyFormatter.format(totalExpense),
    ]);
    _appendRow(sheet, [
      'Saldo',
      CurrencyFormatter.format(totalIncome - totalExpense),
    ]);
    _appendRow(sheet, ['Jumlah transaksi', transactions.length.toString()]);
    _appendRow(sheet, [
      'Jumlah target tabungan',
      savingGoals.length.toString(),
    ]);
    _appendRow(sheet, ['Jumlah budget', budgets.length.toString()]);
    _appendRow(sheet, ['Jumlah tagihan', bills.length.toString()]);
    _appendRow(sheet, ['Jumlah tagihan belum lunas', unpaidBills.toString()]);
    _appendRow(sheet, [
      'Jumlah tagihan lewat jatuh tempo',
      overdueBills.toString(),
    ]);
  }

  void _buildTransactionSheet(
    Excel excel,
    List<TransactionModel> transactions,
  ) {
    final sheet = excel['Transaksi'];
    final sortedTransactions = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    _appendRow(sheet, [
      'No',
      'Tanggal',
      'Judul',
      'Tipe',
      'Kategori',
      'Nominal',
      'Catatan',
    ]);

    for (var index = 0; index < sortedTransactions.length; index++) {
      final transaction = sortedTransactions[index];
      _appendRow(sheet, [
        '${index + 1}',
        _date(transaction.date),
        transaction.title,
        transaction.isIncome ? 'Pemasukan' : 'Pengeluaran',
        transaction.category,
        CurrencyFormatter.format(transaction.amount),
        transaction.note.isEmpty ? '-' : transaction.note,
      ]);
    }
  }

  void _buildSavingGoalSheet(Excel excel, List<SavingGoalModel> savingGoals) {
    final sheet = excel['Target Tabungan'];
    _appendRow(sheet, [
      'No',
      'Nama Target',
      'Target Nominal',
      'Nominal Terkumpul',
      'Progress',
      'Deadline',
      'Status',
      'Catatan',
    ]);

    for (var index = 0; index < savingGoals.length; index++) {
      final goal = savingGoals[index];
      _appendRow(sheet, [
        '${index + 1}',
        goal.title,
        CurrencyFormatter.format(goal.targetAmount),
        CurrencyFormatter.format(goal.currentAmount),
        '${goal.progressPercent}%',
        _date(goal.deadline),
        goal.isCompleted ? 'Tercapai' : 'Berjalan',
        goal.note.isEmpty ? '-' : goal.note,
      ]);
    }
  }

  void _buildBudgetSheet(
    Excel excel,
    List<BudgetModel> budgets,
    List<TransactionModel> transactions,
  ) {
    final sheet = excel['Budget'];
    _appendRow(sheet, [
      'No',
      'Kategori',
      'Bulan',
      'Tahun',
      'Limit Budget',
      'Total Pengeluaran Kategori',
      'Persentase Terpakai',
      'Status',
      'Catatan',
    ]);

    for (var index = 0; index < budgets.length; index++) {
      final budget = budgets[index];
      final categoryExpense = _categoryExpense(budget, transactions);
      final usage = budget.limitAmount <= 0
          ? 0.0
          : (categoryExpense / budget.limitAmount) * 100;

      _appendRow(sheet, [
        '${index + 1}',
        budget.category,
        budget.month.toString().padLeft(2, '0'),
        '${budget.year}',
        CurrencyFormatter.format(budget.limitAmount),
        CurrencyFormatter.format(categoryExpense),
        '${usage.toStringAsFixed(1)}%',
        _budgetStatus(usage),
        budget.note.isEmpty ? '-' : budget.note,
      ]);
    }
  }

  void _buildBillSheet(Excel excel, List<BillModel> bills) {
    final sheet = excel['Tagihan'];
    final sortedBills = [...bills]
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    _appendRow(sheet, [
      'No',
      'Judul',
      'Kategori',
      'Nominal',
      'Jatuh Tempo',
      'Reminder H-berapa',
      'Status Lunas',
      'Catatan',
    ]);

    for (var index = 0; index < sortedBills.length; index++) {
      final bill = sortedBills[index];
      _appendRow(sheet, [
        '${index + 1}',
        bill.title,
        bill.category,
        CurrencyFormatter.format(bill.amount),
        _date(bill.dueDate),
        'H-${bill.reminderDaysBefore}',
        bill.isPaid ? 'Lunas' : 'Belum lunas',
        bill.note.isEmpty ? '-' : bill.note,
      ]);
    }
  }

  double _categoryExpense(
    BudgetModel budget,
    List<TransactionModel> transactions,
  ) {
    return transactions
        .where(
          (transaction) =>
              transaction.isExpense &&
              transaction.category == budget.category &&
              transaction.date.month == budget.month &&
              transaction.date.year == budget.year,
        )
        .fold(0, (total, transaction) => total + transaction.amount);
  }

  String _budgetStatus(double usage) {
    if (usage >= 100) return 'Terlampaui';
    if (usage >= 75) return 'Hampir Habis';
    return 'Aman';
  }

  void _appendRow(Sheet sheet, List<String> values) {
    sheet.appendRow(values.map((value) => TextCellValue(value)).toList());
  }

  String _date(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

  String _dateTime(DateTime value) {
    return DateFormat('yyyy-MM-dd HH:mm').format(value);
  }
}
