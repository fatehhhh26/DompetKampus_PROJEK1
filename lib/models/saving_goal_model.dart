class SavingGoalModel {
  const SavingGoalModel({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    required this.note,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String note;
  final bool isCompleted;

  double get progress {
    if (targetAmount <= 0) return 0;
    return (currentAmount / targetAmount).clamp(0, 1);
  }

  int get progressPercent => (progress * 100).round();

  SavingGoalModel copyWith({
    String? id,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? note,
    bool? isCompleted,
  }) {
    final nextCurrentAmount = currentAmount ?? this.currentAmount;
    final nextTargetAmount = targetAmount ?? this.targetAmount;

    return SavingGoalModel(
      id: id ?? this.id,
      title: title ?? this.title,
      targetAmount: nextTargetAmount,
      currentAmount: nextCurrentAmount,
      deadline: deadline ?? this.deadline,
      note: note ?? this.note,
      isCompleted: isCompleted ?? nextCurrentAmount >= nextTargetAmount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'deadline': deadline.toIso8601String(),
      'note': note,
      'isCompleted': isCompleted,
    };
  }

  factory SavingGoalModel.fromMap(Map<dynamic, dynamic> map) {
    final targetAmount = _readAmount(map['targetAmount']);
    final currentAmount = _readAmount(map['currentAmount']);

    return SavingGoalModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      targetAmount: targetAmount,
      currentAmount: currentAmount,
      deadline:
          DateTime.tryParse(map['deadline']?.toString() ?? '') ??
          DateTime.now(),
      note: map['note']?.toString() ?? '',
      isCompleted: currentAmount >= targetAmount,
    );
  }

  static double _readAmount(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }
}
