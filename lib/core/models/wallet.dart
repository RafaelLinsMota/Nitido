enum WalletType { conta_corrente, poupanca, carteira, credito }

class Wallet {
  final String id;
  final String userId;
  final String name;
  final WalletType type;
  final double balance;
  final String color;
  final String icon;
  final bool isDefault;
  final DateTime createdAt;

  const Wallet({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    this.balance = 0,
    required this.color,
    required this.icon,
    this.isDefault = false,
    required this.createdAt,
  });

  factory Wallet.fromMap(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      type: WalletType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => WalletType.conta_corrente,
      ),
      balance: (json['balance'] as num?)?.toDouble() ?? 0,
      color: json['color'] as String? ?? '#6C63FF',
      icon: json['icon'] as String? ?? 'account_balance_wallet',
      isDefault: json['is_default'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'type': type.name,
      'balance': balance,
      'color': color,
      'icon': icon,
      'is_default': isDefault,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Wallet copyWith({
    String? id,
    String? userId,
    String? name,
    WalletType? type,
    double? balance,
    String? color,
    String? icon,
    bool? isDefault,
    DateTime? createdAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get typeName {
    switch (type) {
      case WalletType.conta_corrente:
        return 'Conta Corrente';
      case WalletType.poupanca:
        return 'Poupança';
      case WalletType.carteira:
        return 'Carteira';
      case WalletType.credito:
        return 'Cartão de Crédito';
    }
  }
}
