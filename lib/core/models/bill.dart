enum BillType { fixa, variavel, parcelada }
enum BillStatus { pendente, paga, atrasada }

class Bill {
  final String id;
  final String userId;
  final String? walletId;
  final String categoryId;
  final String title;
  final double amount;
  final BillType type;
  final DateTime dueDate;
  final BillStatus status;
  final int? installmentCurrent;
  final int? installmentTotal;
  final String? groupId;
  final DateTime? paidAt;
  final DateTime createdAt;

  const Bill({
    required this.id,
    required this.userId,
    this.walletId,
    required this.categoryId,
    required this.title,
    required this.amount,
    required this.type,
    required this.dueDate,
    this.status = BillStatus.pendente,
    this.installmentCurrent,
    this.installmentTotal,
    this.groupId,
    this.paidAt,
    required this.createdAt,
  });

  factory Bill.fromJson(Map<String, dynamic> json) {
    return Bill(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      walletId: json['wallet_id'] as String?,
      categoryId: json['category_id'] as String,
      title: json['title'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: BillType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BillType.variavel,
      ),
      dueDate: DateTime.parse(json['due_date'] as String),
      status: BillStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => BillStatus.pendente,
      ),
      installmentCurrent: json['installment_current'] as int?,
      installmentTotal: json['installment_total'] as int?,
      groupId: json['group_id'] as String?,
      paidAt: json['paid_at'] != null
          ? DateTime.parse(json['paid_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'wallet_id': walletId,
      'category_id': categoryId,
      'title': title,
      'amount': amount,
      'type': type.name,
      'due_date': dueDate.toIso8601String(),
      'status': status.name,
      'installment_current': installmentCurrent,
      'installment_total': installmentTotal,
      'group_id': groupId,
      'paid_at': paidAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Bill copyWith({
    String? id,
    String? userId,
    String? walletId,
    String? categoryId,
    String? title,
    double? amount,
    BillType? type,
    DateTime? dueDate,
    BillStatus? status,
    int? installmentCurrent,
    int? installmentTotal,
    String? groupId,
    DateTime? paidAt,
    DateTime? createdAt,
  }) {
    return Bill(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      walletId: walletId ?? this.walletId,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      installmentCurrent: installmentCurrent ?? this.installmentCurrent,
      installmentTotal: installmentTotal ?? this.installmentTotal,
      groupId: groupId ?? this.groupId,
      paidAt: paidAt ?? this.paidAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isOverdue {
    if (status == BillStatus.paga) return false;
    return dueDate.isBefore(DateTime.now());
  }

  bool get isUrgent {
    if (status == BillStatus.paga) return false;
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    return daysUntilDue <= 3 && daysUntilDue >= 0;
  }
}
