import 'package:uuid/uuid.dart';
import '../supabase/supabase_config.dart';
import '../models/models.dart';

class BillsService {
  static const _uuid = Uuid();

  static Future<void> createBill({
    required String userId,
    required String categoryId,
    required String title,
    required double amount,
    required BillType type,
    required DateTime dueDate,
    int? totalInstallments,
    String? walletId,
  }) async {
    if (type == BillType.parcelada && totalInstallments != null && totalInstallments > 1) {
      await _createInstallmentBills(
        userId: userId,
        categoryId: categoryId,
        title: title,
        amount: amount,
        totalInstallments: totalInstallments,
        startDate: dueDate,
        walletId: walletId,
      );
    } else {
      await SupabaseConfig.client.from('bills').insert({
        'id': _uuid.v4(),
        'user_id': userId,
        'category_id': categoryId,
        'title': title,
        'amount': amount,
        'type': type.name,
        'due_date': dueDate.toIso8601String(),
        'status': 'pendente',
        'wallet_id': walletId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }
  }

  static Future<void> _createInstallmentBills({
    required String userId,
    required String categoryId,
    required String title,
    required double amount,
    required int totalInstallments,
    required DateTime startDate,
    String? walletId,
  }) async {
    final groupId = _uuid.v4();
    final bills = <Map<String, dynamic>>[];

    for (int i = 0; i < totalInstallments; i++) {
      final dueDate = DateTime(
        startDate.year,
        startDate.month + i,
        startDate.day,
      );

      bills.add({
        'id': _uuid.v4(),
        'user_id': userId,
        'category_id': categoryId,
        'title': title,
        'amount': amount,
        'type': 'parcelada',
        'due_date': dueDate.toIso8601String(),
        'status': 'pendente',
        'installment_current': i + 1,
        'installment_total': totalInstallments,
        'group_id': groupId,
        'wallet_id': walletId,
        'created_at': DateTime.now().toIso8601String(),
      });
    }

    await SupabaseConfig.client.from('bills').insert(bills);
  }

  static Future<void> markAsPaid(String billId) async {
    await SupabaseConfig.client.from('bills').update({
      'status': 'paga',
      'paid_at': DateTime.now().toIso8601String(),
    }).eq('id', billId);
  }

  static Future<void> updateBill(String billId, Map<String, dynamic> updates) async {
    await SupabaseConfig.client.from('bills').update(updates).eq('id', billId);
  }

  static Future<void> deleteBill(String billId) async {
    await SupabaseConfig.client.from('bills').delete().eq('id', billId);
  }

  static Future<void> deleteInstallmentGroup(String groupId) async {
    await SupabaseConfig.client.from('bills').delete().eq('group_id', groupId);
  }
}
