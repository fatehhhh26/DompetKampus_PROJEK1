class TransactionModel {
  const TransactionModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    required this.note,
  });

  static const incomeType = 'income';
  static const expenseType = 'expense';

  final String id;
  final String title;
  final double amount;
  final String type;
  final String category;
  final DateTime date;
  final String note;

  bool get isIncome => type == incomeType;
  bool get isExpense => type == expenseType;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'note': note,
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'type': type,
      'category': category,
      'date': _formatDate(date),
      'note': note,
    };
  }

  factory TransactionModel.fromMap(Map<dynamic, dynamic> map) {
    final rawType = map['type']?.toString() ?? expenseType;
    final normalizedType = rawType == incomeType ? incomeType : expenseType;

    return TransactionModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: _readAmount(map['amount']),
      type: normalizedType,
      category: map['category']?.toString() ?? 'Umum',
      date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
      note: map['note']?.toString() ?? '',
    );
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel.fromMap(json);
  }

  static double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
