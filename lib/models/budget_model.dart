class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.category,
    required this.month,
    required this.year,
    required this.limitAmount,
    required this.note,
    required this.createdAt,
  });

  final String id;
  final String category;
  final int month;
  final int year;
  final double limitAmount;
  final String note;
  final DateTime createdAt;

  BudgetModel copyWith({
    String? id,
    String? category,
    int? month,
    int? year,
    double? limitAmount,
    String? note,
    DateTime? createdAt,
  }) {
    return BudgetModel(
      id: id ?? this.id,
      category: category ?? this.category,
      month: month ?? this.month,
      year: year ?? this.year,
      limitAmount: limitAmount ?? this.limitAmount,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category': category,
      'month': month,
      'year': year,
      'limitAmount': limitAmount,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseMap() {
    return {
      'id': id,
      'category': category,
      'month': month,
      'year': year,
      'limit_amount': limitAmount,
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BudgetModel.fromMap(Map<dynamic, dynamic> map) {
    return BudgetModel(
      id: map['id']?.toString() ?? '',
      category: map['category']?.toString() ?? '',
      month: _readInt(map['month'], DateTime.now().month),
      year: _readInt(map['year'], DateTime.now().year),
      limitAmount: _readAmount(map['limitAmount'] ?? map['limit_amount']),
      note: map['note']?.toString() ?? '',
      createdAt:
          DateTime.tryParse(
            (map['createdAt'] ?? map['created_at'])?.toString() ?? '',
          ) ??
          DateTime.now(),
    );
  }

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    return BudgetModel.fromMap(json);
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  static double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
