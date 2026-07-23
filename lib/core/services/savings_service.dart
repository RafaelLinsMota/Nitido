import 'package:uuid/uuid.dart';
import '../supabase/supabase_config.dart';
import '../models/models.dart';

class SavingsService {
  static const _uuid = Uuid();

  static Future<SavingsGoal> createGoal({
    required String userId,
    required String title,
    required double targetAmount,
    DateTime? deadline,
    String? icon,
  }) async {
    final response = await SupabaseConfig.client.from('savings_goals').insert({
      'id': _uuid.v4(),
      'user_id': userId,
      'title': title,
      'target_amount': targetAmount,
      'current_amount': 0.0,
      'deadline': deadline?.toIso8601String(),
      'icon': icon,
      'created_at': DateTime.now().toIso8601String(),
    }).select().single();

    return SavingsGoal.fromMap(response);
  }

  static Future<List<SavingsGoal>> getGoals(String userId) async {
    final response = await SupabaseConfig.client
        .from('savings_goals')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return response.map((data) => SavingsGoal.fromMap(data)).toList();
  }

  static Future<void> updateGoal({
    required String goalId,
    String? title,
    double? targetAmount,
    double? currentAmount,
    DateTime? deadline,
    String? icon,
  }) async {
    final updates = <String, dynamic>{};
    if (title != null) updates['title'] = title;
    if (targetAmount != null) updates['target_amount'] = targetAmount;
    if (currentAmount != null) updates['current_amount'] = currentAmount;
    if (deadline != null) updates['deadline'] = deadline.toIso8601String();
    if (icon != null) updates['icon'] = icon;

    await SupabaseConfig.client
        .from('savings_goals')
        .update(updates)
        .eq('id', goalId);
  }

  static Future<void> deposit({
    required String goalId,
    required String userId,
    required String title,
    required double amount,
  }) async {
    final response = await SupabaseConfig.client
        .from('savings_goals')
        .select('current_amount')
        .eq('id', goalId)
        .single();

    final currentAmount = (response['current_amount'] as num).toDouble();
    await SupabaseConfig.client
        .from('savings_goals')
        .update({'current_amount': currentAmount + amount})
        .eq('id', goalId);

    await SupabaseConfig.client.from('bills').insert({
      'id': _uuid.v4(),
      'user_id': userId,
      'category_id': '550e8400-e29b-41d4-a716-446655440008',
      'title': 'Depósito: $title',
      'amount': amount,
      'type': 'variavel',
      'due_date': DateTime.now().toIso8601String(),
      'status': 'paga',
      'paid_at': DateTime.now().toIso8601String(),
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  static Future<void> deleteGoal(String goalId) async {
    await SupabaseConfig.client.from('savings_goals').delete().eq('id', goalId);
  }

  static Future<double> getTotalSaved(String userId) async {
    final response = await SupabaseConfig.client
        .from('savings_goals')
        .select('current_amount')
        .eq('user_id', userId);

    double total = 0;
    for (var item in response) {
      total += (item['current_amount'] as num).toDouble();
    }
    return total;
  }
}
