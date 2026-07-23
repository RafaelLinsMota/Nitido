import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase/supabase_config.dart';
import '../models/models.dart';
import '../services/wallets_service.dart';

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

final walletsProvider = FutureProvider<List<Wallet>>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return [];
  return WalletsService.getWallets();
});

final selectedWalletIdProvider = StateProvider<String?>((ref) => null);

final selectedWalletProvider = Provider<Wallet?>((ref) {
  final wallets = ref.watch(walletsProvider);
  final selectedId = ref.watch(selectedWalletIdProvider);

  return wallets.when(
    data: (list) {
      if (selectedId != null) {
        return list.where((w) => w.id == selectedId).firstOrNull;
      }
      return list.where((w) => w.isDefault).firstOrNull ??
          (list.isNotEmpty ? list.first : null);
    },
    loading: () => null,
    error: (_, __) => null,
  );
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
  final selectedWallet = ref.watch(selectedWalletProvider);

  return bills.when(
    data: (list) => list.where((bill) {
      final matchesMonth =
          bill.dueDate.year == month.year && bill.dueDate.month == month.month;
      if (selectedWallet == null) return matchesMonth;
      return matchesMonth && bill.groupId == null;
    }).where((bill) {
      if (selectedWallet == null) return true;
      return true;
    }).toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

final monthlySummaryProvider = Provider.family<MonthlySummary, DateTime>((ref, month) {
  final bills = ref.watch(billsForMonthProvider(month));
  final incomes = ref.watch(incomesProvider);
  final selectedWallet = ref.watch(selectedWalletProvider);

  final monthIncomes = incomes.when(
    data: (list) => list.where((inc) {
      final matchesMonth =
          inc.receivedAt.year == month.year && inc.receivedAt.month == month.month;
      if (selectedWallet == null) return matchesMonth;
      return matchesMonth && inc.walletId == selectedWallet.id;
    }).toList(),
    loading: () => <Income>[],
    error: (_, __) => <Income>[],
  );

  final filteredBills = selectedWallet != null
      ? bills.where((b) => b.groupId == null).toList()
      : bills;

  final totalIncome =
      monthIncomes.fold<double>(0, (sum, inc) => sum + inc.amount);
  final totalExpenses =
      filteredBills.fold<double>(0, (sum, bill) => sum + bill.amount);
  final paidExpenses = filteredBills
      .where((b) => b.status == BillStatus.paga)
      .fold<double>(0, (sum, bill) => sum + bill.amount);
  final pendingExpenses = filteredBills
      .where((b) => b.status != BillStatus.paga)
      .fold<double>(0, (sum, bill) => sum + bill.amount);
  final pendingCount = filteredBills.where((b) => b.status != BillStatus.paga).length;
  final overdueCount = filteredBills.where((b) => b.isOverdue).length;

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
