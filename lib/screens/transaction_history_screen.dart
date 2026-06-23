import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/transaction_card.dart';
import 'add_transaction_screen.dart';

class TransactionHistoryScreen extends StatelessWidget {
  const TransactionHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final transactions = provider.transactions;

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: transactions.isEmpty
          ? const EmptyStateWidget(
              icon: Icons.receipt_long_outlined,
              title: 'Belum ada transaksi',
              message:
                  'Transaksi pemasukan dan pengeluaran akan muncul di sini.',
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];

                return TransactionCard(
                  transaction: transaction,
                  onTap: () => _openEditTransaction(context, transaction),
                  onDelete: () => _confirmDelete(context, transaction.id),
                );
              },
            ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Hapus transaksi?'),
          content: const Text(
            'Transaksi yang dihapus tidak bisa dikembalikan.',
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
    await context.read<TransactionProvider>().deleteTransaction(id);
  }

  Future<void> _openEditTransaction(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(transaction: transaction),
      ),
    );

    if (updated != true || !context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil diperbarui.')),
    );
  }
}
