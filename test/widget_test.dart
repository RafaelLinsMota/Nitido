import 'package:flutter_test/flutter_test.dart';
import 'package:nitido/core/models/models.dart';

void main() {
  group('Bill model', () {
    test('fromJson and toJson roundtrip', () {
      final futureDue = DateTime.now().add(const Duration(days: 30));
      final json = {
        'id': '1',
        'user_id': 'u1',
        'category_id': 'c1',
        'title': 'Aluguel',
        'amount': 1500.0,
        'type': 'fixa',
        'due_date': futureDue.toIso8601String(),
        'status': 'pendente',
        'installment_current': null,
        'installment_total': null,
        'group_id': null,
        'paid_at': null,
        'created_at': '2026-01-01T00:00:00.000',
      };

      final bill = Bill.fromJson(json);
      expect(bill.title, 'Aluguel');
      expect(bill.amount, 1500.0);
      expect(bill.type, BillType.fixa);
      expect(bill.status, BillStatus.pendente);
      expect(bill.isOverdue, false);
      expect(bill.isUrgent, false);

      final output = bill.toJson();
      expect(output['title'], 'Aluguel');
      expect(output['amount'], 1500.0);
    });

    test('copyWith creates modified copy', () {
      final bill = Bill(
        id: '1',
        userId: 'u1',
        categoryId: 'c1',
        title: 'Conta',
        amount: 100,
        type: BillType.variavel,
        dueDate: DateTime(2026, 7, 15),
        createdAt: DateTime(2026, 1, 1),
      );

      final paid = bill.copyWith(status: BillStatus.paga, paidAt: DateTime(2026, 7, 16));
      expect(paid.status, BillStatus.paga);
      expect(paid.title, 'Conta');
      expect(paid.paidAt, DateTime(2026, 7, 16));
    });

    test('isOverdue returns true for past due unpaid bills', () {
      final bill = Bill(
        id: '1',
        userId: 'u1',
        categoryId: 'c1',
        title: 'Antiga',
        amount: 100,
        type: BillType.variavel,
        dueDate: DateTime(2020, 1, 1),
        createdAt: DateTime(2020, 1, 1),
      );
      expect(bill.isOverdue, true);
      expect(bill.isUrgent, false);
    });

    test('isUrgent returns true for bills due within 3 days', () {
      final in2Days = DateTime.now().add(const Duration(days: 2));
      final bill = Bill(
        id: '1',
        userId: 'u1',
        categoryId: 'c1',
        title: 'Urgente',
        amount: 100,
        type: BillType.variavel,
        dueDate: in2Days,
        createdAt: DateTime.now(),
      );
      expect(bill.isUrgent, true);
    });

    test('paid bill is not overdue nor urgent', () {
      final past = DateTime.now().subtract(const Duration(days: 30));
      final bill = Bill(
        id: '1',
        userId: 'u1',
        categoryId: 'c1',
        title: 'Paga',
        amount: 100,
        type: BillType.variavel,
        dueDate: past,
        status: BillStatus.paga,
        paidAt: past,
        createdAt: past,
      );
      expect(bill.isOverdue, false);
      expect(bill.isUrgent, false);
    });
  });

  group('Income model', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': '1',
        'user_id': 'u1',
        'title': 'Salário',
        'amount': 5000.0,
        'recurring': true,
        'recurrence_day': 5,
        'received_at': '2026-07-05T00:00:00.000',
        'created_at': '2026-01-01T00:00:00.000',
      };

      final income = Income.fromJson(json);
      expect(income.title, 'Salário');
      expect(income.amount, 5000.0);
      expect(income.recurring, true);
      expect(income.recurrenceDay, 5);

      final output = income.toJson();
      expect(output['title'], 'Salário');
      expect(output['amount'], 5000.0);
    });

    test('copyWith creates modified copy', () {
      final income = Income(
        id: '1',
        userId: 'u1',
        title: 'Freela',
        amount: 1000,
        receivedAt: DateTime(2026, 7, 10),
        createdAt: DateTime(2026, 1, 1),
      );

      final modified = income.copyWith(amount: 1200);
      expect(modified.amount, 1200);
      expect(modified.title, 'Freela');
    });
  });

  group('Category model', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'c1',
        'user_id': null,
        'name': 'Moradia',
        'icon': 'home',
        'color': '#A78BFA',
      };

      final cat = Category.fromJson(json);
      expect(cat.name, 'Moradia');
      expect(cat.icon, 'home');
      expect(cat.color, '#A78BFA');

      final output = cat.toJson();
      expect(output['name'], 'Moradia');
    });

    test('copyWith creates modified copy', () {
      final cat = Category(id: 'c1', name: 'Casa', icon: 'home', color: '#000');
      final modified = cat.copyWith(name: 'Apartamento');
      expect(modified.name, 'Apartamento');
      expect(cat.name, 'Casa');
    });
  });

  group('UserProfile model', () {
    test('fromJson and toJson roundtrip', () {
      final json = {
        'id': 'u1',
        'name': 'Rafael',
        'email': 'rafa@email.com',
        'created_at': '2026-01-01T00:00:00.000',
      };

      final profile = UserProfile.fromJson(json);
      expect(profile.name, 'Rafael');
      expect(profile.email, 'rafa@email.com');

      final output = profile.toJson();
      expect(output['name'], 'Rafael');
      expect(output['email'], 'rafa@email.com');
    });
  });
}
