import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';
import '../models/models.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return SupabaseConfig.auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  return SupabaseConfig.auth.currentUser;
});

final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  final response = await SupabaseConfig.client
      .from('users')
      .select()
      .eq('id', user.id)
      .single();

  return UserProfile.fromJson(response);
});

final incomesProvider = FutureProvider<List<Income>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final response = await SupabaseConfig.client
      .from('incomes')
      .select()
      .eq('user_id', user.id)
      .order('received_at', ascending: false);

  return (response as List).map((json) => Income.fromJson(json)).toList();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final response = await SupabaseConfig.client
      .from('categories')
      .select()
      .or('user_id.is.null,user_id.eq.${user.id}')
      .order('name');

  return (response as List).map((json) => Category.fromJson(json)).toList();
});

final billsProvider = FutureProvider<List<Bill>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];

  final response = await SupabaseConfig.client
      .from('bills')
      .select()
      .eq('user_id', user.id)
      .order('due_date', ascending: true);

  return (response as List).map((json) => Bill.fromJson(json)).toList();
});

final billsForMonthProvider = Provider.family<List<Bill>, DateTime>((ref, month) {
  final bills = ref.watch(billsProvider);
  return bills.when(
    data: (list) => list.where((bill) {
      return bill.dueDate.year == month.year && bill.dueDate.month == month.month;
    }).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final monthlySummaryProvider = Provider.family<MonthlySummary, DateTime>((ref, month) {
  final bills = ref.watch(billsForMonthProvider(month));
  final incomes = ref.watch(incomesProvider);

  final monthIncomes = incomes.when(
    data: (list) => list.where((inc) {
      return inc.receivedAt.year == month.year && inc.receivedAt.month == month.month;
    }).toList(),
    loading: () => <Income>[],
    error: (_, __) => <Income>[],
  );

  final totalIncome = monthIncomes.fold<double>(0, (sum, inc) => sum + inc.amount);
  final totalExpenses = bills.fold<double>(0, (sum, bill) => sum + bill.amount);
  final paidExpenses = bills
      .where((b) => b.status == BillStatus.paga)
      .fold<double>(0, (sum, bill) => sum + bill.amount);
  final pendingExpenses = bills
      .where((b) => b.status != BillStatus.paga)
      .fold<double>(0, (sum, bill) => sum + bill.amount);
  final pendingCount = bills.where((b) => b.status != BillStatus.paga).length;
  final overdueCount = bills.where((b) => b.isOverdue).length;

  return MonthlySummary(
    totalIncome: totalIncome,
    totalExpenses: totalExpenses,
    paidExpenses: paidExpenses,
    pendingExpenses: pendingExpenses,
    pendingCount: pendingCount,
    overdueCount: overdueCount,
    balance: totalIncome - totalExpenses,
  );
});

class MonthlySummary {
  final double totalIncome;
  final double totalExpenses;
  final double paidExpenses;
  final double pendingExpenses;
  final int pendingCount;
  final int overdueCount;
  final double balance;

  const MonthlySummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.paidExpenses,
    required this.pendingExpenses,
    required this.pendingCount,
    required this.overdueCount,
    required this.balance,
  });
}
