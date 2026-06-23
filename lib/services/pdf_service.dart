import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/utils/currency_formatter.dart';
import '../models/transaction_model.dart';

class PdfService {
  Future<Uint8List> generateFinancialReport({
    required List<TransactionModel> transactions,
    required double balance,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final pdf = pw.Document();
    final generatedAt = DateFormat(
      'EEEE, dd MMMM yyyy HH:mm',
      'id_ID',
    ).format(DateTime.now());
    final sortedTransactions = [...transactions]
      ..sort((a, b) => b.date.compareTo(a.date));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            _buildHeader(generatedAt),
            pw.SizedBox(height: 24),
            _buildSummary(
              balance: balance,
              totalIncome: totalIncome,
              totalExpense: totalExpense,
              transactionCount: transactions.length,
            ),
            pw.SizedBox(height: 28),
            pw.Text(
              'Daftar Transaksi',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 12),
            if (sortedTransactions.isEmpty)
              _buildEmptyTransactionInfo()
            else
              _buildTransactionTable(sortedTransactions),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String generatedAt) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Laporan Keuangan DompetKampus',
          style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Text(
          'Tanggal pembuatan laporan: $generatedAt',
          style: const pw.TextStyle(color: PdfColors.grey700),
        ),
      ],
    );
  }

  pw.Widget _buildSummary({
    required double balance,
    required double totalIncome,
    required double totalExpense,
    required int transactionCount,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(10),
        border: pw.Border.all(color: PdfColors.blue100),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            children: [
              _buildSummaryItem('Saldo', CurrencyFormatter.format(balance)),
              _buildSummaryItem(
                'Total Pemasukan',
                CurrencyFormatter.format(totalIncome),
              ),
            ],
          ),
          pw.SizedBox(height: 14),
          pw.Row(
            children: [
              _buildSummaryItem(
                'Total Pengeluaran',
                CurrencyFormatter.format(totalExpense),
              ),
              _buildSummaryItem('Jumlah Transaksi', '$transactionCount'),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryItem(String label, String value) {
    return pw.Expanded(
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildEmptyTransactionInfo() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Text('Belum ada data transaksi untuk ditampilkan.'),
    );
  }

  pw.Widget _buildTransactionTable(List<TransactionModel> transactions) {
    return pw.TableHelper.fromTextArray(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.6),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.blue100),
      headerStyle: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: 8),
      cellAlignment: pw.Alignment.centerLeft,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      columnWidths: const {
        0: pw.FlexColumnWidth(1.2),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
        3: pw.FlexColumnWidth(1),
        4: pw.FlexColumnWidth(1.1),
        5: pw.FlexColumnWidth(1.4),
      },
      headers: const [
        'Tanggal',
        'Judul',
        'Kategori',
        'Jenis',
        'Nominal',
        'Catatan',
      ],
      data: transactions.map((transaction) {
        final typeLabel = transaction.isIncome ? 'Pemasukan' : 'Pengeluaran';
        final signedAmount =
            '${transaction.isIncome ? '+' : '-'}${CurrencyFormatter.format(transaction.amount)}';

        return [
          DateFormat('dd MMM yyyy', 'id_ID').format(transaction.date),
          transaction.title,
          transaction.category,
          typeLabel,
          signedAmount,
          transaction.note.isEmpty ? '-' : transaction.note,
        ];
      }).toList(),
    );
  }
}
