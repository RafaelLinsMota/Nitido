import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:nitido/core/theme/app_theme.dart';
import 'package:nitido/core/providers/providers.dart';
import 'package:nitido/core/models/models.dart';
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
    final summary = ref.watch(monthlySummaryProvider(currentMonth));
    final bills = ref.watch(billsForMonthProvider(currentMonth));
    final incomes = ref.watch(incomesProvider);
    final user = ref.watch(userProfileProvider);

    final userName = user.when(
      data: (profile) => profile?.name ?? 'Usuário',
      loading: () => 'Usuário',
      error: (_, __) => 'Usuário',
    );

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
                        _buildHeader(userName),
                        const SizedBox(height: 18),
                        _buildBalanceCard(summary),
                        const SizedBox(height: 14),
                        _buildStatCards(summary),
                        const SizedBox(height: 14),
                        _buildBudgetSummary(monthBills, summary),
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

  Widget _buildHeader(String userName) {
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

class NewEntrySheet extends StatefulWidget {
  final bool isIncome;

  const NewEntrySheet({super.key, required this.isIncome});

  @override
  State<NewEntrySheet> createState() => _NewEntrySheetState();
}

class _NewEntrySheetState extends State<NewEntrySheet> {
  late bool isIncome;
  String? selectedCategoryId;
  BillType billType = BillType.fixa;
  int installments = 3;
  bool recurring = true;
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
    {'id': 'housing', 'name': 'Moradia', 'icon': Icons.home, 'color': const Color(0xFFA78BFA)},
    {'id': 'food', 'name': 'Alimentação', 'icon': Icons.restaurant, 'color': const Color(0xFFFB923C)},
    {'id': 'transport', 'name': 'Transporte', 'icon': Icons.directions_car, 'color': const Color(0xFF38BDF8)},
    {'id': 'leisure', 'name': 'Lazer', 'icon': Icons.sports_esports, 'color': const Color(0xFFF472B6)},
    {'id': 'health', 'name': 'Saúde', 'icon': Icons.favorite, 'color': AppColors.textSecondary},
    {'id': 'other_expense', 'name': 'Outros', 'icon': Icons.more_horiz, 'color': AppColors.textSecondary},
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
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleSubmit,
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
                      child: Text(
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

  void _handleSubmit() {
    Navigator.pop(context);
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
