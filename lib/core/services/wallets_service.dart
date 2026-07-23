import 'package:uuid/uuid.dart';
import '../supabase/supabase_config.dart';
import '../models/models.dart';

class WalletsService {
  static const _uuid = Uuid();

  static Future<Wallet> createWallet({
    required String name,
    required WalletType type,
    String color = '#6C63FF',
    String icon = 'account_balance_wallet',
    bool isDefault = false,
  }) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) throw Exception('Usuário não autenticado');

    final id = _uuid.v4();
    final data = {
      'id': id,
      'user_id': user.id,
      'name': name,
      'type': type.name,
      'balance': 0,
      'color': color,
      'icon': icon,
      'is_default': isDefault,
    };

    final response = await SupabaseConfig.client
        .from('wallets')
        .insert(data)
        .select()
        .single();

    return Wallet.fromMap(response);
  }

  static Future<List<Wallet>> getWallets() async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return [];

    final response = await SupabaseConfig.client
        .from('wallets')
        .select()
        .eq('user_id', user.id)
        .order('is_default', ascending: false)
        .order('name');

    return (response as List).map((json) => Wallet.fromMap(json)).toList();
  }

  static Future<Wallet> updateWallet(String id, Map<String, dynamic> data) async {
    final response = await SupabaseConfig.client
        .from('wallets')
        .update(data)
        .eq('id', id)
        .select()
        .single();

    return Wallet.fromMap(response);
  }

  static Future<void> deleteWallet(String id) async {
    await SupabaseConfig.client.from('wallets').delete().eq('id', id);
  }

  static Future<void> setDefault(String id) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return;

    await SupabaseConfig.client
        .from('wallets')
        .update({'is_default': false})
        .eq('user_id', user.id);

    await SupabaseConfig.client
        .from('wallets')
        .update({'is_default': true})
        .eq('id', id);
  }

  static double getTotalBalanceSync(List<Wallet> wallets) {
    return wallets.fold<double>(0, (sum, w) {
      if (w.type == WalletType.credito) return sum - w.balance.abs();
      return sum + w.balance;
    });
  }

  static Future<double> getTotalBalance() async {
    final wallets = await getWallets();
    return wallets.fold<double>(0, (sum, w) {
      if (w.type == WalletType.credito) return sum - w.balance.abs();
      return sum + w.balance;
    });
  }

  static Future<Map<String, dynamic>> getWalletSummary(
      String walletId, DateTime month) async {
    final user = SupabaseConfig.auth.currentUser;
    if (user == null) return {'income': 0.0, 'expenses': 0.0, 'balance': 0.0};

    final bills = await SupabaseConfig.client
        .from('bills')
        .select('amount, status')
        .eq('user_id', user.id)
        .eq('wallet_id', walletId);

    final incomes = await SupabaseConfig.client
        .from('incomes')
        .select('amount, received_at')
        .eq('user_id', user.id)
        .eq('wallet_id', walletId);

    final monthExpenses = (bills as List)
        .where((b) {
          final due = DateTime.parse(b['due_date'] ?? b['created_at']);
          return due.year == month.year && due.month == month.month;
        })
        .fold<double>(0, (sum, b) => sum + (b['amount'] as num).toDouble());

    final monthIncome = (incomes as List)
        .where((i) {
          final received = DateTime.parse(i['received_at']);
          return received.year == month.year && received.month == month.month;
        })
        .fold<double>(0, (sum, i) => sum + (i['amount'] as num).toDouble());

    return {
      'income': monthIncome,
      'expenses': monthExpenses,
      'balance': monthIncome - monthExpenses,
    };
  }
}
