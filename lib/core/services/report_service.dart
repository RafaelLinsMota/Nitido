import 'dart:io';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../supabase/supabase_config.dart';
import '../models/models.dart';

class ReportService {
  static Future<File> generateMonthlyReport({
    required String userId,
    required DateTime month,
  }) async {
    final monthKey = month.toIso8601String().substring(0, 7);
    final monthLabel = DateFormat('MMMM yyyy', 'pt_BR').format(month);

    final billsResponse = await SupabaseConfig.client
        .from('bills')
        .select()
        .eq('user_id', userId)
        .gte('due_date', '$monthKey-01')
        .lte('due_date', '$monthKey-31')
        .order('due_date');

    final incomesResponse = await SupabaseConfig.client
        .from('incomes')
        .select()
        .eq('user_id', userId)
        .gte('received_at', '$monthKey-01')
        .lte('received_at', '$monthKey-31')
        .order('received_at');

    final categoriesResponse = await SupabaseConfig.client
        .from('categories')
        .select()
        .or('user_id.is.null,user_id.eq.$userId');

    final budgetsResponse = await SupabaseConfig.client
        .from('budgets')
        .select()
        .eq('user_id', userId)
        .eq('month', monthKey);

    final categoryMap = <String, String>{};
    for (var cat in categoriesResponse) {
      categoryMap[cat['id']] = cat['name'];
    }

    final bills = (billsResponse as List).map((b) => Bill.fromJson(b)).toList();
    final incomes = (incomesResponse as List).map((i) => Income.fromJson(i)).toList();

    final totalIncome = incomes.fold<double>(0, (s, i) => s + i.amount);
    final totalExpenses = bills.fold<double>(0, (s, b) => s + b.amount);
    final paidExpenses = bills.where((b) => b.status == BillStatus.paga).fold<double>(0, (s, b) => s + b.amount);
    final pendingExpenses = bills.where((b) => b.status != BillStatus.paga).fold<double>(0, (s, b) => s + b.amount);

    final categoryTotals = <String, double>{};
    for (var bill in bills) {
      final catName = categoryMap[bill.categoryId] ?? 'Outros';
      categoryTotals[catName] = (categoryTotals[catName] ?? 0) + bill.amount;
    }

    final pdf = pw.Document();

    final headerStyle = pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold);
    final subHeaderStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700);
    final bodyStyle = pw.TextStyle(fontSize: 11);
    final boldStyle = pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Nítido - Relatório Mensal', style: headerStyle),
          ),
          pw.Text(monthLabel.toUpperCase(), style: subHeaderStyle),
          pw.SizedBox(height: 20),

          pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey100,
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Resumo Geral', style: subHeaderStyle),
                pw.SizedBox(height: 8),
                _buildSummaryRow('Total de Receitas', currencyFormat.format(totalIncome)),
                _buildSummaryRow('Total de Despesas', currencyFormat.format(totalExpenses)),
                _buildSummaryRow('Saldo', currencyFormat.format(totalIncome - totalExpenses)),
                pw.Divider(),
                _buildSummaryRow('Despesas Pagas', currencyFormat.format(paidExpenses)),
                _buildSummaryRow('Despesas Pendentes', currencyFormat.format(pendingExpenses)),
                _buildSummaryRow('Contas Pendentes', '${bills.where((b) => b.status != BillStatus.paga).length}'),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          if (categoryTotals.isNotEmpty) ...[
            pw.Text('Despesas por Categoria', style: subHeaderStyle),
            pw.SizedBox(height: 8),
            ...categoryTotals.entries.map((e) {
              final percent = totalExpenses > 0 ? ((e.value / totalExpenses) * 100).toInt() : 0;
              return _buildSummaryRow('${e.key} ($percent%)', currencyFormat.format(e.value));
            }),
            pw.SizedBox(height: 24),
          ],

          if (incomes.isNotEmpty) ...[
            pw.Text('Receitas', style: subHeaderStyle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Descrição', 'Valor'],
              headerStyle: boldStyle,
              cellStyle: bodyStyle,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              data: incomes.map((i) => [
                DateFormat('dd/MM').format(i.receivedAt),
                i.title,
                currencyFormat.format(i.amount),
              ]).toList(),
            ),
            pw.SizedBox(height: 24),
          ],

          if (bills.isNotEmpty) ...[
            pw.Text('Despesas', style: subHeaderStyle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Data', 'Descrição', 'Categoria', 'Valor', 'Status'],
              headerStyle: boldStyle,
              cellStyle: bodyStyle,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              data: bills.map((b) => [
                DateFormat('dd/MM').format(b.dueDate),
                b.title,
                categoryMap[b.categoryId] ?? '-',
                currencyFormat.format(b.amount),
                b.status == BillStatus.paga ? 'Paga' : 'Pendente',
              ]).toList(),
            ),
            pw.SizedBox(height: 24),
          ],

          if (budgetsResponse.isNotEmpty) ...[
            pw.Text('Orçamentos', style: subHeaderStyle),
            pw.SizedBox(height: 8),
            pw.TableHelper.fromTextArray(
              headers: ['Categoria', 'Limite', 'Gasto', 'Status'],
              headerStyle: boldStyle,
              cellStyle: bodyStyle,
              headerDecoration: pw.BoxDecoration(color: PdfColors.grey200),
              data: budgetsResponse.map((b) {
                final catName = categoryMap[b['category_id']] ?? '-';
                final limit = (b['amount'] as num).toDouble();
                final spent = categoryTotals[catName] ?? 0.0;
                final status = spent > limit ? 'Excedido' : '${((spent / limit) * 100).toInt()}%';
                return [catName, currencyFormat.format(limit), currencyFormat.format(spent), status];
              }).toList(),
            ),
          ],

          pw.SizedBox(height: 32),
          pw.Divider(),
          pw.Center(
            child: pw.Text(
              'Gerado em ${DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(DateTime.now())}',
              style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ),
        ],
      ),
    );

    final output = Directory.systemTemp;
    final fileName = 'nitido_relatorio_$monthKey.pdf';
    final file = File('${output.path}/$fileName');
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  static pw.Widget _buildSummaryRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: 11)),
          pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  static Future<void> shareReport(File file) async {
    if (Platform.isWindows) {
      await Process.run('cmd', ['/c', 'start', '', file.path]);
    } else if (Platform.isMacOS) {
      await Process.run('open', [file.path]);
    } else {
      await Process.run('xdg-open', [file.path]);
    }
  }
}
