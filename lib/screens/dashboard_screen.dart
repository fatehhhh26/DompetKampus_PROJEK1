import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
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
    final latestTransactions = transactions.latestTransactions;

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
        child: SingleChildScrollView(
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
              BalanceCard(
                balance: transactions.balance,
                income: transactions.totalIncome,
                expense: transactions.totalExpense,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '5 transaksi terbaru',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
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
              if (latestTransactions.isEmpty)
                const EmptyStateWidget(
                  icon: Icons.receipt_long_outlined,
                  title: 'Belum ada transaksi',
                  message: 'Mulai catat pemasukan atau pengeluaran pertamamu.',
                )
              else
                for (final transaction in latestTransactions)
                  TransactionCard(transaction: transaction),
            ],
          ),
        ),
      ),
    );
  }
}
