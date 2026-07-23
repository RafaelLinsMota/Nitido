import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:nitido/core/theme/app_theme.dart';
import 'package:nitido/core/providers/providers.dart';
import 'package:nitido/core/models/models.dart';
import 'package:nitido/core/services/bills_service.dart';
import 'package:nitido/shared/widgets/glass_widgets.dart';
import 'package:nitido/features/home/home_screen.dart';

class BillsScreen extends ConsumerStatefulWidget {
  const BillsScreen({super.key});

  @override
  ConsumerState<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends ConsumerState<BillsScreen> {
  BillFilter filter = BillFilter.todas;
  late DateTime currentMonth;
  bool isFabOpen = false;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billsForMonthProvider(currentMonth));

    final overdue = bills.where((b) => b.isOverdue).toList();
    final pending = bills
        .where((b) => b.status == BillStatus.pendente && !b.isOverdue)
        .toList();
    final paid = bills.where((b) => b.status == BillStatus.paga).toList();
    final totalOpen = [...overdue, ...pending].fold<double>(0, (s, b) => s + b.amount);

    final totalCount = bills.length;
    final pendingCount = overdue.length + pending.length;
    final paidCount = paid.length;

    List<BillListSection> sections;
    if (filter == BillFilter.pagas) {
      sections = [BillListSection(title: 'Pagas', items: paid)];
    } else if (filter == BillFilter.pendentes) {
      sections = [
        if (overdue.isNotEmpty)
          BillListSection(title: 'Atrasadas', items: overdue, accent: AppColors.negative),
        if (pending.isNotEmpty) BillListSection(title: 'A vencer', items: pending),
      ];
    } else {
      sections = [
        if (overdue.isNotEmpty)
          BillListSection(title: 'Atrasadas', items: overdue, accent: AppColors.negative),
        if (pending.isNotEmpty) BillListSection(title: 'A vencer', items: pending),
        if (paid.isNotEmpty) BillListSection(title: 'Pagas', items: paid),
      ];
    }

    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 160),
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 10),
                      _buildMonthSelector(),
                      const SizedBox(height: 6),
                      _buildSummary(totalOpen, overdue.length + pending.length),
                      const SizedBox(height: 16),
                      _buildFilterTabs(totalCount, pendingCount, paidCount),
                      const SizedBox(height: 14),
                      _buildTip(),
                      const SizedBox(height: 4),
                      ...sections.expand((section) => [
                            _buildSectionHeader(section),
                            ...section.items.map((bill) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildBillItem(bill),
                                )),
                          ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 20,
            bottom: 104,
            child: GlassFAB(
              onPressed: () => setState(() => isFabOpen = !isFabOpen),
              isOpen: isFabOpen,
              actions: [
                GlassFABAction(
                  icon: Icons.trending_up,
                  label: 'Receita',
                  color: AppColors.positive,
                  onPressed: () => _showNewEntrySheet(isIncome: true),
                ),
                GlassFABAction(
                  icon: Icons.receipt_long,
                  label: 'Conta',
                  color: AppColors.negative,
                  onPressed: () => _showNewEntrySheet(isIncome: false),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundBlobs() {
    return Stack(
      children: [
        Positioned(
          top: -60,
          left: -60,
          width: 220,
          height: 220,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.violet.withValues(alpha: 0.45),
            ),
          ),
        ),
        Positioned(
          bottom: -40,
          right: -60,
          width: 240,
          height: 240,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.teal.withValues(alpha: 0.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return const Text(
      'Contas',
      style: TextStyle(
        fontFamily: 'Manrope',
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _NavArrow(
          icon: Icons.chevron_left,
          onTap: () => setState(() {
            currentMonth = DateTime(currentMonth.year, currentMonth.month - 1);
          }),
        ),
        Text(
          DateFormat('MMMM yyyy', 'pt_BR').format(currentMonth),
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
        _NavArrow(
          icon: Icons.chevron_right,
          onTap: () => setState(() {
            currentMonth = DateTime(currentMonth.year, currentMonth.month + 1);
          }),
        ),
      ],
    );
  }

  Widget _buildSummary(double totalOpen, int pendingCount) {
    return Text(
      '${_formatBRL(totalOpen)} em aberto · $pendingCount pendentes',
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12,
      ),
    );
  }

  Widget _buildFilterTabs(int totalCount, int pendingCount, int paidCount) {
    return GlassCard(
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          SegmentTab(
            label: 'Todas',
            count: totalCount,
            active: filter == BillFilter.todas,
            onClick: () => setState(() => filter = BillFilter.todas),
          ),
          SegmentTab(
            label: 'Pendentes',
            count: pendingCount,
            active: filter == BillFilter.pendentes,
            onClick: () => setState(() => filter = BillFilter.pendentes),
          ),
          SegmentTab(
            label: 'Pagas',
            count: paidCount,
            active: filter == BillFilter.pagas,
            onClick: () => setState(() => filter = BillFilter.pagas),
          ),
        ],
      ),
    );
  }

  Widget _buildTip() {
    return const Text(
      'Dica: arraste um item para a esquerda para marcar como pago',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 11,
        fontStyle: FontStyle.italic,
      ),
    );
  }

  Widget _buildSectionHeader(BillListSection section) {
    final subtotal = section.items.fold<double>(0, (s, b) => s + b.amount);
    return Padding(
      padding: const EdgeInsets.only(top: 18, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            section.title,
            style: TextStyle(
              color: section.accent ?? AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              textBaseline: TextBaseline.alphabetic,
            ),
          ),
          Text(
            _formatBRL(subtotal),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillItem(Bill bill) {
    return Slidable(
      endActionPane: ActionPane(
        motion: const BehindMotion(),
        extentRatio: 0.25,
        children: [
          SlidableAction(
            onPressed: (_) => _markAsPaid(bill),
            backgroundColor: AppColors.teal,
            foregroundColor: Colors.white,
            icon: Icons.check,
            label: 'Pago',
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(26),
              bottom: Radius.circular(26),
            ),
          ),
        ],
      ),
      child: GlassCard(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withValues(alpha: 0.15),
              ),
              child: const Icon(Icons.receipt_long, size: 18, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          bill.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (bill.installmentCurrent != null && bill.installmentTotal != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                          child: Text(
                            '${bill.installmentCurrent}/${bill.installmentTotal}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getBillSubtitle(bill),
                    style: TextStyle(
                      color: _getSubtitleColor(bill),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (bill.status == BillStatus.paga)
                  const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check, size: 11, color: AppColors.positive),
                      SizedBox(width: 3),
                      Text(
                        'Pago',
                        style: TextStyle(
                          color: AppColors.positive,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 3),
                Text(
                  _formatBRL(bill.amount),
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                    decoration: bill.status == BillStatus.paga
                        ? TextDecoration.none
                        : TextDecoration.none,
                    decorationColor: AppColors.textSecondary.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getBillSubtitle(Bill bill) {
    if (bill.status == BillStatus.paga && bill.paidAt != null) {
      return 'Pago em ${DateFormat('dd/MM').format(bill.paidAt!)}';
    }
    final daysUntil = bill.dueDate.difference(DateTime.now()).inDays;
    if (bill.isOverdue) return 'Venceu há ${-daysUntil} dias';
    if (daysUntil == 0) return 'Vence hoje';
    if (daysUntil == 1) return 'Vence amanhã';
    return 'Vence em $daysUntil dias';
  }

  Color _getSubtitleColor(Bill bill) {
    if (bill.status == BillStatus.paga) return AppColors.textSecondary;
    if (bill.isOverdue) return AppColors.negative;
    if (bill.isUrgent) return AppColors.warning;
    return AppColors.textSecondary;
  }

  Future<void> _markAsPaid(Bill bill) async {
    try {
      await BillsService.markAsPaid(bill.id);
      ref.invalidate(billsProvider);
      ref.invalidate(billsForMonthProvider(currentMonth));
      ref.invalidate(monthlySummaryProvider(currentMonth));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao marcar como pago: $e')),
        );
      }
    }
  }

  void _showNewEntrySheet({required bool isIncome}) {
    setState(() => isFabOpen = false);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => NewEntrySheet(isIncome: isIncome),
    );
  }

  String _formatBRL(double value) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }
}

enum BillFilter { todas, pendentes, pagas }

class BillListSection {
  final String title;
  final List<Bill> items;
  final Color? accent;

  const BillListSection({
    required this.title,
    required this.items,
    this.accent,
  });
}

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.08),
        ),
        child: Icon(icon, size: 18, color: AppColors.textSecondary),
      ),
    );
  }
}
