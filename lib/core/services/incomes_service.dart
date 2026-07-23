import 'package:uuid/uuid.dart';
import '../supabase/supabase_config.dart';

class IncomesService {
  static const _uuid = Uuid();

  static Future<void> createIncome({
    required String userId,
    required String title,
    required double amount,
    required bool recurring,
    int? recurrenceDay,
    required DateTime receivedAt,
    String? walletId,
  }) async {
    await SupabaseConfig.client.from('incomes').insert({
      'id': _uuid.v4(),
      'user_id': userId,
      'title': title,
      'amount': amount,
      'recurring': recurring,
      'recurrence_day': recurrenceDay,
      'received_at': receivedAt.toIso8601String(),
      'wallet_id': walletId,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> updateIncome(String incomeId, Map<String, dynamic> updates) async {
    await SupabaseConfig.client.from('incomes').update(updates).eq('id', incomeId);
  }

  static Future<void> deleteIncome(String incomeId) async {
    await SupabaseConfig.client.from('incomes').delete().eq('id', incomeId);
  }
}
