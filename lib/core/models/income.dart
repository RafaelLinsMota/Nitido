class Income {
  final String id;
  final String userId;
  final String? walletId;
  final String title;
  final double amount;
  final bool recurring;
  final int? recurrenceDay;
  final DateTime receivedAt;
  final DateTime createdAt;

  const Income({
    required this.id,
    required this.userId,
    this.walletId,
    required this.title,
    required this.amount,
    this.recurring = false,
    this.recurrenceDay,
    required this.receivedAt,
    required this.createdAt,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      walletId: json['wallet_id'] as String?,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      recurring: json['recurring'] as bool? ?? false,
      recurrenceDay: json['recurrence_day'] as int?,
      receivedAt: DateTime.parse(json['received_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'title': title,
      'amount': amount,
      'recurring': recurring,
      'recurrence_day': recurrenceDay,
      'received_at': receivedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Income copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? title,
    double? amount,
    bool? recurring,
    int? recurrenceDay,
    DateTime? receivedAt,
    DateTime? createdAt,
  }) {
    return Income(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      recurring: recurring ?? this.recurring,
      recurrenceDay: recurrenceDay ?? this.recurrenceDay,
      receivedAt: receivedAt ?? this.receivedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
