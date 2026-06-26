import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/transaction_model.dart';
import '../providers/transaction_provider.dart';
import '../widgets/app_feedback_dialog.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/transaction_card.dart';
import 'transaction_detail_screen.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionProvider>();
    final filteredTransactions = _applySearch(provider.filteredTransactions);

    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MonthFilterHeader(provider: provider),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Cari transaksi',
                      hintText: 'Judul, kategori, atau catatan',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Hapus pencarian',
                              icon: const Icon(Icons.close_rounded),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.trim());
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () =>
                    context.read<TransactionProvider>().loadTransactions(),
                child: provider.isLoading
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(
                            height: 320,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ],
                      )
                    : provider.errorMessage != null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          EmptyStateWidget(
                            icon: Icons.wifi_off_rounded,
                            title: 'Gagal memuat transaksi',
                            message: provider.errorMessage!,
                          ),
                        ],
                      )
                    : filteredTransactions.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        children: [
                          EmptyStateWidget(
                            icon: Icons.receipt_long_outlined,
                            title: 'Tidak ada transaksi',
                            message:
                                'Coba ubah filter bulan atau kata kunci pencarian.',
                          ),
                        ],
                      )
                    : ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];

                          return TransactionCard(
                            transaction: transaction,
                            onTap: () => _openDetail(context, transaction),
                            onDelete: () =>
                                _confirmDelete(context, transaction.id),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionModel> _applySearch(List<TransactionModel> transactions) {
    final query = _searchQuery.toLowerCase();
    if (query.isEmpty) return transactions;

    return transactions.where((transaction) {
      return transaction.title.toLowerCase().contains(query) ||
          transaction.category.toLowerCase().contains(query) ||
          transaction.note.toLowerCase().contains(query);
    }).toList();
  }

  void _openDetail(BuildContext context, TransactionModel transaction) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => TransactionDetailScreen(transactionId: transaction.id),
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
    final provider = context.read<TransactionProvider>();
    final success = await provider.deleteTransaction(id);
    if (!context.mounted) return;

    if (!success) {
      await AppFeedbackDialog.showError(
        context,
        message: provider.errorMessage ?? 'Gagal menghapus transaksi.',
      );
      return;
    }

    await AppFeedbackDialog.showSuccess(
      context,
      message: 'Transaksi berhasil dihapus.',
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
