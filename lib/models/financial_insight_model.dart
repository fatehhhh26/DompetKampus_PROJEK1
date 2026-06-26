class FinancialInsightModel {
  const FinancialInsightModel({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.severity,
    required this.createdAt,
  });

  static const typeSummary = 'summary';
  static const typeSpending = 'spending';
  static const typeBudget = 'budget';
  static const typeSaving = 'saving';
  static const typeBill = 'bill';
  static const typeRecommendation = 'recommendation';

  static const severityInfo = 'info';
  static const severitySuccess = 'success';
  static const severityWarning = 'warning';
  static const severityDanger = 'danger';

  final String id;
  final String title;
  final String message;
  final String type;
  final String severity;
  final DateTime createdAt;

  factory FinancialInsightModel.fromMap(Map<dynamic, dynamic> map) {
    return FinancialInsightModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      message: map['message']?.toString() ?? '',
      type: map['type']?.toString() ?? typeSummary,
      severity: map['severity']?.toString() ?? severityInfo,
      createdAt:
          DateTime.tryParse(map['createdAt']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'severity': severity,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
