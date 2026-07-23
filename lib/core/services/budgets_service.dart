import 'package:uuid/uuid.dart';
import '../supabase/supabase_config.dart';
import '../models/models.dart';

class BudgetsService {
  static const _uuid = Uuid();

  static Future<void> createOrUpdateBudget({
    required String userId,
    required String categoryId,
    required double amount,
    required DateTime month,
  }) async {
    final monthKey = month.toIso8601String().substring(0, 7); // YYYY-MM format
    
    // Check if budget already exists for this user, category and month
    final response = await SupabaseConfig.client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('category_id', categoryId)
        .eq('month', monthKey);

    if (response.isEmpty) {
      // Create new budget
      await SupabaseConfig.client.from('budgets').insert({
        'id': _uuid.v4(),
        'user_id': userId,
        'category_id': categoryId,
        'amount': amount,
        'month': monthKey,
        'created_at': DateTime.now().toIso8601String(),
      });
    } else {
      // Update existing budget
      final budgetId = response[0]['id'];
      await SupabaseConfig.client.from('budgets').update({
        'amount': amount,
      }).eq('id', budgetId);
    }
  }

  static Future<List<Budget>> getBudgetsForMonth(String userId, DateTime month) async {
    final monthKey = month.toIso8601String().substring(0, 7);
    final response = await SupabaseConfig.client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('month', monthKey);

    return response.map((data) => Budget.fromMap(data)).toList();
  }

  static Future<void> deleteBudget(String budgetId) async {
    await SupabaseConfig.client.from('budgets').delete().eq('id', budgetId);
  }

  static Future<void> deleteBudgetsForMonth(String userId, DateTime month) async {
    final monthKey = month.toIso8601String().substring(0, 7);
    await SupabaseConfig.client.from('budgets').delete()
        .eq('user_id', userId)
        .eq('month', monthKey);
  }

  static Future<void> resetMonth(String userId, DateTime month) async {
    final monthKey = month.toIso8601String().substring(0, 7);
    final firstDay = '$monthKey-01';
    final lastDay = '$monthKey-31';

    await SupabaseConfig.client.from('budgets').delete()
        .eq('user_id', userId)
        .eq('month', monthKey);

    await SupabaseConfig.client.from('bills').delete()
        .eq('user_id', userId)
        .gte('due_date', firstDay)
        .lte('due_date', lastDay);

    await SupabaseConfig.client.from('incomes').delete()
        .eq('user_id', userId)
        .gte('received_at', firstDay)
        .lte('received_at', lastDay);
  }

  // Get current spending for each category in a month
  static Future<Map<String, Map<String, dynamic>>> getCategorySpending(String userId, DateTime month) async {
    final monthKey = month.toIso8601String().substring(0, 7);
    final response = await SupabaseConfig.client
        .from('bills')
        .select('category_id, amount')
        .eq('user_id', userId)
        .gte('due_date', '${monthKey}-01')
        .lte('due_date', '${monthKey}-31');

    // Group by category and sum amounts
    final spendingByCategory = <String, Map<String, dynamic>>{};
    for (var item in response) {
      final categoryId = item['category_id'];
      final amount = (item['amount'] as num).toDouble();
      if (!spendingByCategory.containsKey(categoryId)) {
        spendingByCategory[categoryId] = {
          'amount': amount,
          'budget': 0.0,
        };
      } else {
        spendingByCategory[categoryId]!['amount'] += amount;
      }
    }

    // Fetch budgets and ensure every budgeted category appears
    final budgetsResponse = await SupabaseConfig.client
        .from('budgets')
        .select('category_id, amount')
        .eq('user_id', userId)
        .eq('month', monthKey);

    for (var budget in budgetsResponse) {
      final categoryId = budget['category_id'];
      final budgetAmount = (budget['amount'] as num).toDouble();
      if (spendingByCategory.containsKey(categoryId)) {
        spendingByCategory[categoryId]!['budget'] = budgetAmount;
      } else {
        spendingByCategory[categoryId] = {
          'amount': 0.0,
          'budget': budgetAmount,
        };
      }
    }

    return spendingByCategory;
  }
}
