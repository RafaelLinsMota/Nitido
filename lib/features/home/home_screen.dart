import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nitido/core/theme/app_theme.dart';
import 'package:nitido/core/providers/providers.dart';
import 'package:nitido/core/models/models.dart';
import 'package:nitido/core/services/incomes_service.dart';
import 'package:nitido/core/services/bills_service.dart';
import 'package:nitido/core/services/budgets_service.dart';
import 'package:nitido/shared/widgets/glass_widgets.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool isFabOpen = false;
  late DateTime currentMonth;

  @override
  void initState() {
    super.initState();
    currentMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final bills = ref.watch(billsForMonthProvider(currentMonth));

    final monthBills = bills;
    final upcomingBills = monthBills
        .where((b) => b.status != BillStatus.paga)
        .take(4)
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(monthlySummaryProvider(currentMonth));
                      ref.invalidate(billsProvider);
                      ref.invalidate(incomesProvider);
                    },
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 160),
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildWalletSelector(),
                        const SizedBox(height: 14),
                        Consumer(builder: (context, ref, _) {
                          final summary = ref.watch(monthlySummaryProvider(currentMonth));
                          return _buildBalanceCard(summary);
                        }),
                        const SizedBox(height: 14),
                        Consumer(builder: (context, ref, _) {
                          final summary = ref.watch(monthlySummaryProvider(currentMonth));
                          return _buildStatCards(summary);
                        }),
                        const SizedBox(height: 14),
                        Consumer(builder: (context, ref, _) {
                          final s = ref.watch(monthlySummaryProvider(currentMonth));
                          return _buildBudgetSummary(monthBills, s);
                        }),
                        const SizedBox(height: 14),
                        Consumer(builder: (context, ref, _) {
                          return _buildBudgetAlerts();
                        }),
                        const SizedBox(height: 20),
                        _buildUpcomingSection(upcomingBills),
                      ],
                    ),
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
    return Consumer(builder: (context, ref, _) {
      final user = ref.watch(userProfileProvider);
      final userName = user.when(
        data: (profile) => profile?.name ?? 'Usuário',
        loading: () => 'Usuário',
        error: (_, __) => 'Usuário',
      );
      final now = DateTime.now();
      final dateStr = DateFormat('EEEE, d \'de\' MMMM', 'pt_BR').format(now);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Olá, $userName',
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          Text(
            dateStr,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildWalletSelector() {
    return Consumer(builder: (context, ref, _) {
      final wallets = ref.watch(walletsProvider);
      final selectedWallet = ref.watch(selectedWalletProvider);

      return wallets.when(
        data: (list) {
          if (list.isEmpty) return const SizedBox.shrink();

          return SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length + 1,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  final isSelected = selectedWallet == null;
                  return GestureDetector(
                    onTap: () =>
                        ref.read(selectedWalletIdProvider.notifier).state = null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.white.withValues(alpha: 0.06),
                        border: Border.all(
                          color: isSelected
                              ? Colors.white.withValues(alpha: 0.3)
                              : Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                      child: const Text(
                        'Todas',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }

                final wallet = list[index - 1];
                final isSelected = selectedWallet?.id == wallet.id;
                final walletColor = _parseHexColor(wallet.color);

                return GestureDetector(
                  onTap: () => ref.read(selectedWalletIdProvider.notifier).state =
                      wallet.id,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: isSelected
                          ? walletColor.withValues(alpha: 0.25)
                          : Colors.white.withValues(alpha: 0.06),
                      border: Border.all(
                        color: isSelected
                            ? walletColor
                            : Colors.white.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: walletColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          wallet.name,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.textPrimary
                                : AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );
    });
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  Widget _buildBalanceCard(MonthlySummary summary) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Saldo disponível',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            _formatBRL(summary.balance),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(
                summary.balance >= 0 ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: summary.balance >= 0 ? AppColors.positive : AppColors.negative,
              ),
              const SizedBox(width: 4),
              Text(
                summary.balance >= 0 ? 'Positivo' : 'Negativo',
                style: TextStyle(
                  color: summary.balance >= 0 ? AppColors.positive : AppColors.negative,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards(MonthlySummary summary) {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            icon: Icons.trending_up,
            label: 'Receitas',
            value: _formatBRL(summary.totalIncome),
            color: AppColors.positive,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.trending_down,
            label: 'Despesas',
            value: _formatBRL(summary.totalExpenses),
            color: AppColors.negative,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: StatCard(
            icon: Icons.notifications_outlined,
            label: 'A vencer',
            value: '${summary.pendingCount} contas',
            color: AppColors.warning,
          ),
        ),
      ],
    );
  }

  Widget _buildBudgetSummary(List<Bill> bills, MonthlySummary summary) {
    final categoryTotals = <String, double>{};
    for (final bill in bills) {
      categoryTotals[bill.categoryId] =
          (categoryTotals[bill.categoryId] ?? 0) + bill.amount;
    }

    final totalExpenses = summary.totalExpenses;
    if (totalExpenses == 0) return const SizedBox.shrink();

    final categories = [
      {'name': 'Moradia', 'color': const Color(0xFFA78BFA), 'percent': 35},
      {'name': 'Alimentação', 'color': const Color(0xFFFB923C), 'percent': 24},
      {'name': 'Transporte', 'color': const Color(0xFF38BDF8), 'percent': 15},
      {'name': 'Lazer', 'color': const Color(0xFFF472B6), 'percent': 14},
      {'name': 'Outros', 'color': const Color(0xFF94A3B8), 'percent': 12},
    ];

    final R = 45.0;
    final C = 2 * 3.14159 * R;
    double cumulative = 0;

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_outline, size: 15, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              const Text(
                'Resumo do orçamento',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              SizedBox(
                width: 110,
                height: 110,
                child: CustomPaint(
                  painter: _DonutPainter(categories, cumulative),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Total gasto',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 10),
                        ),
                        Text(
                          _formatBRL(totalExpenses),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: categories.map((cat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cat['color'] as Color,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              cat['name'] as String,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(
                            '${cat['percent']}%',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetAlerts() {
    final user = ref.read(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    return FutureBuilder<Map<String, Map<String, dynamic>>>(
      future: BudgetsService.getCategorySpending(user.id, currentMonth),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final spending = snapshot.data!;
        final overBudgetCategories = <String, Map<String, dynamic>>{};

        for (var entry in spending.entries) {
          final spent = entry.value['amount'] ?? 0.0;
          final budget = entry.value['budget'] ?? 0.0;
          if (budget > 0 && spent > budget) {
            overBudgetCategories[entry.key] = entry.value;
          }
        }

        if (overBudgetCategories.isEmpty) return const SizedBox.shrink();

        final categories = ref.watch(categoriesProvider);
        final categoryMap = categories.when(
          data: (list) => {for (var c in list) c.id: c.name},
          loading: () => <String, String>{},
          error: (_, __) => <String, String>{},
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 18, color: AppColors.warning),
                const SizedBox(width: 6),
                const Text(
                  'Alertas de Orçamento',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...overBudgetCategories.entries.map((entry) {
              final spent = entry.value['amount'] ?? 0.0;
              final budget = entry.value['budget'] ?? 0.0;
              final percent = ((spent / budget) * 100).toInt();
              final diff = spent - budget;

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GlassCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Categoria: ${categoryMap[entry.key] ?? entry.key}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.negative.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$percent%',
                            style: const TextStyle(
                              color: AppColors.negative,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: (spent / budget).clamp(0.0, 1.5),
                        backgroundColor: Colors.white.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          spent > budget ? AppColors.negative : AppColors.warning,
                        ),
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Gasto: ${_formatBRL(spent)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        Text(
                          'Limite: ${_formatBRL(budget)}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ultrapassou em ${_formatBRL(diff)}',
                      style: const TextStyle(
                        color: AppColors.negative,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildUpcomingSection(List<Bill> upcomingBills) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Próximos vencimentos',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  'Ver todas',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                Icon(Icons.chevron_right, size: 13, color: AppColors.textSecondary),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        ...upcomingBills.map((bill) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _BillCard(bill: bill),
            )),
      ],
    );
  }

  void _showNewEntrySheet({required bool isIncome}) {
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

class _BillCard extends StatelessWidget {
  final Bill bill;

  const _BillCard({required this.bill});

  @override
  Widget build(BuildContext context) {
    final daysUntil = bill.dueDate.difference(DateTime.now()).inDays;
    final isUrgent = daysUntil <= 3 && daysUntil >= 0;

    return GlassCard(
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
                Text(
                  bill.title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'vence em $daysUntil ${daysUntil == 1 ? 'dia' : 'dias'}',
                  style: TextStyle(
                    color: isUrgent ? AppColors.negative : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatBRL(bill.amount),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBRL(double value) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }
}

class _DonutPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  final double initialOffset;

  _DonutPainter(this.categories, this.initialOffset);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 12;
    final strokeWidth = 14.0;
    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -3.14159 / 2;
    final total = categories.fold<double>(0, (sum, cat) => sum + (cat['percent'] as int));

    for (final cat in categories) {
      final sweepAngle = (cat['percent'] as int) / total * 2 * 3.14159;
      final paint = Paint()
        ..color = cat['color'] as Color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class NewEntrySheet extends ConsumerStatefulWidget {
  final bool isIncome;

  const NewEntrySheet({super.key, required this.isIncome});

  @override
  ConsumerState<NewEntrySheet> createState() => _NewEntrySheetState();
}

class _NewEntrySheetState extends ConsumerState<NewEntrySheet> {
  late bool isIncome;
  String? selectedCategoryId;
  String? selectedWalletId;
  BillType billType = BillType.fixa;
  int installments = 3;
  bool recurring = true;
  bool isLoading = false;
  final amountController = TextEditingController(text: '0,00');
  final descriptionController = TextEditingController();
  DateTime selectedDate = DateTime.now();

  final incomeCategories = [
    {'id': 'salary', 'name': 'Salário', 'icon': Icons.work_outline, 'color': AppColors.positive},
    {'id': 'freelance', 'name': 'Freelance', 'icon': Icons.laptop, 'color': const Color(0xFF38BDF8)},
    {'id': 'invest', 'name': 'Investim.', 'icon': Icons.trending_up, 'color': const Color(0xFFA78BFA)},
    {'id': 'other_income', 'name': 'Outros', 'icon': Icons.more_horiz, 'color': AppColors.textSecondary},
  ];

  final expenseCategories = [
    {'id': '550e8400-e29b-41d4-a716-446655440001', 'name': 'Moradia', 'icon': Icons.home, 'color': const Color(0xFFA78BFA)},
    {'id': '550e8400-e29b-41d4-a716-446655440002', 'name': 'Alimentação', 'icon': Icons.restaurant, 'color': const Color(0xFFFB923C)},
    {'id': '550e8400-e29b-41d4-a716-446655440003', 'name': 'Transporte', 'icon': Icons.directions_car, 'color': const Color(0xFF38BDF8)},
    {'id': '550e8400-e29b-41d4-a716-446655440004', 'name': 'Lazer', 'icon': Icons.sports_esports, 'color': const Color(0xFFF472B6)},
    {'id': '550e8400-e29b-41d4-a716-446655440005', 'name': 'Saúde', 'icon': Icons.favorite, 'color': AppColors.textSecondary},
    {'id': '550e8400-e29b-41d4-a716-446655440008', 'name': 'Outros', 'icon': Icons.more_horiz, 'color': AppColors.textSecondary},
  ];

  @override
  void initState() {
    super.initState();
    isIncome = widget.isIncome;
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get categories =>
      isIncome ? incomeCategories : expenseCategories;

  @override
  Widget build(BuildContext context) {
    final accentGradient = isIncome ? AppColors.mintGradient : AppColors.coralGradient;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: const Color(0xFF141024).withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Novo lançamento',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.08),
                      ),
                      child: const Icon(Icons.close, size: 15, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isIncome = true;
                          selectedCategoryId = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: isIncome ? AppColors.mintGradient : null,
                          ),
                          child: Text(
                            'Receita',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: isIncome
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          isIncome = false;
                          selectedCategoryId = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: !isIncome ? AppColors.coralGradient : null,
                          ),
                          child: Text(
                            'Conta',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: !isIncome
                                  ? AppColors.background
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Valor',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'R\$',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w600,
                            fontSize: 20,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 150,
                          child: TextField(
                            controller: amountController,
                            textAlign: TextAlign.left,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontWeight: FontWeight.w800,
                              fontSize: 38,
                              color: AppColors.textPrimary,
                            ),
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 120,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(1),
                        gradient: accentGradient,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const _FieldLabel('Descrição'),
              TextField(
                controller: descriptionController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: isIncome ? 'Ex: Salário, Freelance...' : 'Ex: Aluguel, Cartão...',
                  hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Categoria'),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final cat = categories[index];
                    final isSelected = selectedCategoryId == cat['id'];
                    final color = cat['color'] as Color;
                    return GestureDetector(
                      onTap: () => setState(() => selectedCategoryId = cat['id'] as String),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: isSelected ? color : color.withValues(alpha: 0.15),
                              border: Border.all(
                                color: isSelected ? color : Colors.white.withValues(alpha: 0.1),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              cat['icon'] as IconData,
                              size: 20,
                              color: isSelected ? AppColors.background : color,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            cat['name'] as String,
                            style: TextStyle(
                              color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (!isIncome) ...[
                const SizedBox(height: 20),
                const _FieldLabel('Tipo'),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                  child: Row(
                    children: BillType.values.map((type) {
                      final isSelected = billType == type;
                      final label = type == BillType.fixa
                          ? 'Fixa'
                          : type == BillType.variavel
                              ? 'Variável'
                              : 'Parcelada';
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => billType = type),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(14),
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.16)
                                  : Colors.transparent,
                            ),
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: isSelected
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
              if (!isIncome && billType == BillType.parcelada) ...[
                const SizedBox(height: 20),
                const _FieldLabel('Número de parcelas'),
                Row(
                  children: [
                    _StepperButton(
                      icon: Icons.remove,
                      onTap: () => setState(() => installments = (installments - 1).clamp(2, 24)),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      '${installments}x',
                      style: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 17,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    _StepperButton(
                      icon: Icons.add,
                      onTap: () => setState(() => installments = (installments + 1).clamp(2, 24)),
                    ),
                  ],
                ),
              ],
              if (!isIncome) ...[
                const SizedBox(height: 20),
                const _FieldLabel('Data de vencimento'),
                GestureDetector(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime.now().subtract(const Duration(days: 365)),
                      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
                    );
                    if (date != null) setState(() => selectedDate = date);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(alpha: 0.06),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            DateFormat('dd \'de\' MMMM \'de\' yyyy', 'pt_BR').format(selectedDate),
                            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                          ),
                        ),
                        Icon(Icons.chevron_right, size: 15, color: AppColors.textSecondary),
                      ],
                    ),
                  ),
                ),
              ],
              if (isIncome) ...[
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Repetir todo mês',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Lança automaticamente todo mês',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => recurring = !recurring),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 46,
                        height: 26,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(13),
                          gradient: recurring ? AppColors.mintGradient : null,
                          color: recurring ? null : Colors.white.withValues(alpha: 0.12),
                        ),
                        child: AnimatedAlign(
                          duration: const Duration(milliseconds: 200),
                          alignment: recurring ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.all(3),
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.3),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 20),
              const _FieldLabel('Carteira'),
              _buildWalletDropdown(),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    backgroundColor: Colors.transparent,
                    foregroundColor: AppColors.background,
                    elevation: 0,
                  ),
                  child: Ink(
                    decoration: BoxDecoration(
                      gradient: accentGradient,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Container(
                      alignment: Alignment.center,
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      child: isLoading
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.background,
                              ),
                            )
                          : Text(
                              isIncome ? 'Adicionar receita' : 'Adicionar conta',
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleSubmit() async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    final amountText = amountController.text
        .replaceAll('.', '')
        .replaceAll(',', '.');
    final amount = double.tryParse(amountText) ?? 0;
    if (amount <= 0 || descriptionController.text.trim().isEmpty) return;

    setState(() => isLoading = true);

    try {
      if (isIncome) {
        await IncomesService.createIncome(
          userId: user.id,
          title: descriptionController.text.trim(),
          amount: amount,
          recurring: recurring,
          recurrenceDay: recurring ? selectedDate.day : null,
          receivedAt: selectedDate,
          walletId: selectedWalletId,
        );
      } else {
        await BillsService.createBill(
          userId: user.id,
          categoryId: selectedCategoryId ?? '',
          title: descriptionController.text.trim(),
          amount: amount,
          type: billType,
          dueDate: selectedDate,
          totalInstallments: billType == BillType.parcelada ? installments : null,
          walletId: selectedWalletId,
        );
      }

      ref.invalidate(incomesProvider);
      ref.invalidate(billsProvider);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Widget _buildWalletDropdown() {
    final wallets = ref.watch(walletsProvider);

    return wallets.when(
      data: (list) {
        if (list.isEmpty) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: const Text(
              'Nenhuma carteira disponível',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          );
        }

        final selected = selectedWalletId != null
            ? list.firstWhere(
                (w) => w.id == selectedWalletId,
                orElse: () => list.first,
              )
            : null;

        return GestureDetector(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (_) => _WalletPickerSheet(
                wallets: list,
                selectedId: selectedWalletId,
                onSelect: (id) => setState(() => selectedWalletId = id),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.account_balance_wallet,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    selected?.name ?? 'Selecionar carteira',
                    style: TextStyle(
                      color: selected != null
                          ? AppColors.textPrimary
                          : AppColors.textTertiary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, size: 15, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StepperButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _StepperButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.10),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

class _WalletPickerSheet extends StatelessWidget {
  final List<Wallet> wallets;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  const _WalletPickerSheet({
    required this.wallets,
    required this.selectedId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.4,
      decoration: BoxDecoration(
        color: const Color(0xFF141024).withValues(alpha: 0.92),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Selecionar carteira',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    GestureDetector(
                      onTap: () {
                        onSelect(null);
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: selectedId == null
                              ? Colors.white.withValues(alpha: 0.16)
                              : Colors.white.withValues(alpha: 0.04),
                          border: Border.all(
                            color: selectedId == null
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                              child: Icon(Icons.all_inclusive,
                                  size: 18, color: AppColors.textSecondary),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Todas as carteiras',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            if (selectedId == null)
                              const Icon(Icons.check, size: 16, color: AppColors.teal),
                          ],
                        ),
                      ),
                    ),
                    ...wallets.map((wallet) {
                      final isSelected = selectedId == wallet.id;
                      final walletColor = _parseHexColor(wallet.color);

                      return GestureDetector(
                        onTap: () {
                          onSelect(wallet.id);
                          Navigator.pop(context);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: isSelected
                                ? walletColor.withValues(alpha: 0.2)
                                : Colors.white.withValues(alpha: 0.04),
                            border: Border.all(
                              color: isSelected
                                  ? walletColor
                                  : Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: walletColor.withValues(alpha: 0.2),
                                ),
                                child: Icon(_getWalletIcon(wallet.type),
                                    size: 18, color: walletColor),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      wallet.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      wallet.typeName,
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Icon(Icons.check, size: 16, color: walletColor),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseHexColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
  }

  IconData _getWalletIcon(WalletType type) {
    switch (type) {
      case WalletType.conta_corrente:
        return Icons.account_balance;
      case WalletType.poupanca:
        return Icons.savings;
      case WalletType.carteira:
        return Icons.account_balance_wallet;
      case WalletType.credito:
        return Icons.credit_card;
    }
  }
}
