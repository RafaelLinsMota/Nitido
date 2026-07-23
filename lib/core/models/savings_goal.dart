class SavingsGoal {
  final String id;
  final String userId;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime? deadline;
  final String? icon;
  final DateTime createdAt;

  SavingsGoal({
    required this.id,
    required this.userId,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    this.deadline,
    this.icon,
    required this.createdAt,
  });

  double get progress => targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

  int get daysRemaining {
    if (deadline == null) return 0;
    return deadline!.difference(DateTime.now()).inDays;
  }

  factory SavingsGoal.fromMap(Map<String, dynamic> data) {
    return SavingsGoal(
      id: data['id'],
      userId: data['user_id'],
      title: data['title'],
      targetAmount: (data['target_amount'] as num).toDouble(),
      currentAmount: (data['current_amount'] as num).toDouble(),
      deadline: data['deadline'] != null ? DateTime.parse(data['deadline']) : null,
      icon: data['icon'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline?.toIso8601String(),
      'icon': icon,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
