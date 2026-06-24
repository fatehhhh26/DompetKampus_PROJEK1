class BillModel {
  const BillModel({
    required this.id,
    required this.title,
    required this.amount,
    required this.dueDate,
    required this.category,
    required this.note,
    required this.isPaid,
    required this.reminderDaysBefore,
    required this.createdAt,
  });

  final String id;
  final String title;
  final double amount;
  final DateTime dueDate;
  final String category;
  final String note;
  final bool isPaid;
  final int reminderDaysBefore;
  final DateTime createdAt;

  bool get isOverdue {
    final today = DateTime.now();
    final todayOnly = DateTime(today.year, today.month, today.day);
    final dueOnly = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return !isPaid && dueOnly.isBefore(todayOnly);
  }

  BillModel copyWith({
    String? id,
    String? title,
    double? amount,
    DateTime? dueDate,
    String? category,
    String? note,
    bool? isPaid,
    int? reminderDaysBefore,
    DateTime? createdAt,
  }) {
    return BillModel(
      id: id ?? this.id,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      dueDate: dueDate ?? this.dueDate,
      category: category ?? this.category,
      note: note ?? this.note,
      isPaid: isPaid ?? this.isPaid,
      reminderDaysBefore: reminderDaysBefore ?? this.reminderDaysBefore,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'dueDate': dueDate.toIso8601String(),
      'category': category,
      'note': note,
      'isPaid': isPaid,
      'reminderDaysBefore': reminderDaysBefore,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'due_date': _formatDate(dueDate),
      'category': category,
      'note': note,
      'is_paid': isPaid,
      'reminder_days_before': reminderDaysBefore,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BillModel.fromMap(Map<dynamic, dynamic> map) {
    return BillModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      amount: _readAmount(map['amount']),
      dueDate:
          DateTime.tryParse(
            (map['dueDate'] ?? map['due_date'])?.toString() ?? '',
          ) ??
          DateTime.now(),
      category: map['category']?.toString() ?? '',
      note: map['note']?.toString() ?? '',
      isPaid: _readBool(map['isPaid'] ?? map['is_paid']),
      reminderDaysBefore: _readInt(
        map['reminderDaysBefore'] ?? map['reminder_days_before'],
        1,
      ),
      createdAt:
          DateTime.tryParse(
            (map['createdAt'] ?? map['created_at'])?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  factory BillModel.fromJson(Map<String, dynamic> json) {
    return BillModel.fromMap(json);
  }

  static double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static bool _readBool(dynamic value) {
    if (value is bool) return value;
    return value?.toString() == 'true';
  }

  static String _formatDate(DateTime value) {
    final year = value.year.toString().padLeft(4, '0');
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
