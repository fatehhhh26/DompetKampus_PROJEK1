import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../core/utils/currency_formatter.dart';
import '../models/transaction_model.dart';

class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
    this.onDelete,
  });

  final TransactionModel transaction;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final color = transaction.isIncome ? AppColors.income : AppColors.expense;
    final icon = transaction.isIncome
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;
    final prefix = transaction.isIncome ? '+' : '-';
    final subtitle = [
      transaction.category,
      DateFormat('dd MMM yyyy', 'id_ID').format(transaction.date),
      if (transaction.note.isNotEmpty) transaction.note,
    ].join(' - ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(
          transaction.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$prefix${CurrencyFormatter.format(transaction.amount)}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            if (onDelete != null) ...[
              const SizedBox(width: 4),
              IconButton(
                tooltip: 'Hapus transaksi',
                icon: const Icon(Icons.delete_outline_rounded),
                onPressed: onDelete,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
