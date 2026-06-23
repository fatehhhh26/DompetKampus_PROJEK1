import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../services/pdf_service.dart';
import '../widgets/custom_button.dart';

class ReportScreen extends StatelessWidget {
  const ReportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final transactionProvider = context.watch<TransactionProvider>();
    final transactions = transactionProvider.transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Laporan Keuangan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              const Text(
                'Ringkasan transaksi siap dibuat menjadi laporan PDF.',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _ReportSummaryGrid(
                balance: transactionProvider.balance,
                totalIncome: transactionProvider.totalIncome,
                totalExpense: transactionProvider.totalExpense,
                transactionCount: transactions.length,
              ),
              const SizedBox(height: 20),
              if (transactions.isEmpty)
                const _EmptyReportInfo()
              else
                _TransactionCountInfo(transactionCount: transactions.length),
              const SizedBox(height: 20),
              CustomButton(
                label: 'Generate PDF',
                icon: Icons.picture_as_pdf_rounded,
                onPressed: () => _sharePdf(context, transactionProvider),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () => _openPreview(context, transactionProvider),
                  icon: const Icon(Icons.preview_rounded),
                  label: const Text('Preview/Share PDF'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sharePdf(
    BuildContext context,
    TransactionProvider provider,
  ) async {
    final bytes = await PdfService().generateFinancialReport(
      transactions: provider.transactions,
      balance: provider.balance,
      totalIncome: provider.totalIncome,
      totalExpense: provider.totalExpense,
    );

    await Printing.sharePdf(bytes: bytes, filename: 'laporan-dompetkampus.pdf');
  }

  void _openPreview(BuildContext context, TransactionProvider provider) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _PdfPreviewScreen(
          transactionsProviderSnapshot: _ReportSnapshot.fromProvider(provider),
        ),
      ),
    );
  }
}

class _ReportSummaryGrid extends StatelessWidget {
  const _ReportSummaryGrid({
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
    required this.transactionCount,
  });

  final double balance;
  final double totalIncome;
  final double totalExpense;
  final int transactionCount;

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
        _ReportSummaryCard(
          label: 'Total saldo',
          value: CurrencyFormatter.format(balance),
          icon: Icons.account_balance_wallet_outlined,
          color: AppColors.primary,
        ),
        _ReportSummaryCard(
          label: 'Pemasukan',
          value: CurrencyFormatter.format(totalIncome),
          icon: Icons.arrow_downward_rounded,
          color: AppColors.income,
        ),
        _ReportSummaryCard(
          label: 'Pengeluaran',
          value: CurrencyFormatter.format(totalExpense),
          icon: Icons.arrow_upward_rounded,
          color: AppColors.expense,
        ),
        _ReportSummaryCard(
          label: 'Transaksi',
          value: '$transactionCount data',
          icon: Icons.receipt_long_outlined,
          color: AppColors.secondary,
        ),
      ],
    );
  }
}

class _ReportSummaryCard extends StatelessWidget {
  const _ReportSummaryCard({
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
            Icon(icon, color: color),
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

class _EmptyReportInfo extends StatelessWidget {
  const _EmptyReportInfo();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Belum ada data transaksi. PDF tetap bisa dibuat dan akan menampilkan informasi kosong.',
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransactionCountInfo extends StatelessWidget {
  const _TransactionCountInfo({required this.transactionCount});

  final int transactionCount;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppColors.background,
          child: Icon(
            Icons.check_circle_outline_rounded,
            color: AppColors.secondary,
          ),
        ),
        title: const Text('Data laporan siap'),
        subtitle: Text(
          '$transactionCount transaksi akan masuk ke laporan PDF.',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

class _PdfPreviewScreen extends StatelessWidget {
  const _PdfPreviewScreen({required this.transactionsProviderSnapshot});

  final _ReportSnapshot transactionsProviderSnapshot;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview Laporan')),
      body: PdfPreview(
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: 'laporan-dompetkampus.pdf',
        build: (_) => PdfService().generateFinancialReport(
          transactions: transactionsProviderSnapshot.transactions,
          balance: transactionsProviderSnapshot.balance,
          totalIncome: transactionsProviderSnapshot.totalIncome,
          totalExpense: transactionsProviderSnapshot.totalExpense,
        ),
      ),
    );
  }
}

class _ReportSnapshot {
  const _ReportSnapshot({
    required this.transactions,
    required this.balance,
    required this.totalIncome,
    required this.totalExpense,
  });

  factory _ReportSnapshot.fromProvider(TransactionProvider provider) {
    return _ReportSnapshot(
      transactions: provider.transactions,
      balance: provider.balance,
      totalIncome: provider.totalIncome,
      totalExpense: provider.totalExpense,
    );
  }

  final List<TransactionModel> transactions;
  final double balance;
  final double totalIncome;
  final double totalExpense;
}
