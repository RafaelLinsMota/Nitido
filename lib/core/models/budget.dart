class Budget {
  final String id;
  final String userId;
  final String categoryId;
  final double amount;
  final String month;

  Budget({
    required this.id,
    required this.userId,
    required this.categoryId,
    required this.amount,
    required this.month,
  });

  factory Budget.fromMap(Map<String, dynamic> data) {
    return Budget(
      id: data['id'],
      userId: data['user_id'],
      categoryId: data['category_id'],
      amount: (data['amount'] as num).toDouble(),
      month: data['month'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'category_id': categoryId,
      'amount': amount,
      'month': month,
    };
  }
}