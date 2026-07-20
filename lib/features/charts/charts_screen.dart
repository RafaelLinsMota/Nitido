import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:nitido/core/theme/app_theme.dart';
import 'package:nitido/core/providers/providers.dart';
import 'package:nitido/core/models/models.dart';
import 'package:nitido/shared/widgets/glass_widgets.dart';

class ChartsScreen extends ConsumerStatefulWidget {
  const ChartsScreen({super.key});

  @override
  ConsumerState<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends ConsumerState<ChartsScreen> {
  int period = 6;
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

    final totalExpenses = summary.totalExpenses;

    final categories = [
      _CategoryData('Moradia', 35, 1246, const Color(0xFFA78BFA)),
      _CategoryData('Alimentação', 24, 854, const Color(0xFFFB923C)),
      _CategoryData('Transporte', 15, 534, const Color(0xFF38BDF8)),
      _CategoryData('Lazer', 14, 498, const Color(0xFFF472B6)),
      _CategoryData('Outros', 12, 427, const Color(0xFF94A3B8)),
    ];

    final ranking = bills
        .where((b) => b.status != BillStatus.paga)
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    final topRanking = ranking.take(5).toList();

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
                      const SizedBox(height: 16),
                      _buildTotalCard(totalExpenses),
                      const SizedBox(height: 14),
                      _buildInsights(),
                      const SizedBox(height: 22),
                      _buildEvolutionSection(),
                      const SizedBox(height: 22),
                      _buildDonutSection(categories, totalExpenses),
                      const SizedBox(height: 22),
                      _buildRankingSection(topRanking),
                    ],
                  ),
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
      'Gráficos',
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

  Widget _buildTotalCard(double totalExpenses) {
    return GlassCard(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total gasto no mês',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 6),
          Text(
            _formatBRL(totalExpenses),
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.trending_down, size: 14, color: AppColors.positive),
              const SizedBox(width: 4),
              Text(
                '-4%',
                style: TextStyle(
                  color: AppColors.positive,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                'vs mês anterior',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInsights() {
    return Column(
      children: [
        _InsightCard(
          icon: Icons.home,
          color: const Color(0xFFA78BFA),
          text: 'Moradia é sua maior categoria este mês, consumindo 35% do total gasto.',
        ),
        const SizedBox(height: 10),
        _InsightCard(
          icon: Icons.trending_down,
          color: AppColors.positive,
          text: 'Você gastou R\$ 140,50 a menos do que em junho.',
        ),
      ],
    );
  }

  Widget _buildEvolutionSection() {
    final monthsData = [
      {'label': 'Ago', 'value': 2980.0},
      {'label': 'Set', 'value': 3120.0},
      {'label': 'Out', 'value': 3400.0},
      {'label': 'Nov', 'value': 3850.0},
      {'label': 'Dez', 'value': 4200.0},
      {'label': 'Jan', 'value': 3050.0},
      {'label': 'Fev', 'value': 2890.0},
      {'label': 'Mar', 'value': 3310.0},
      {'label': 'Abr', 'value': 3180.0},
      {'label': 'Mai', 'value': 3400.0},
      {'label': 'Jun', 'value': 3700.0},
      {'label': 'Jul', 'value': 3559.5},
    ];

    final displayedMonths = monthsData.sublist(monthsData.length - period);
    final maxMonthValue = displayedMonths
        .map((m) => m['value'] as double)
        .reduce((a, b) => a > b ? a : b);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Evolução mensal',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Colors.white.withValues(alpha: 0.06),
              ),
              child: Row(
                children: [3, 6, 12].map((p) {
                  final isSelected = period == p;
                  return GestureDetector(
                    onTap: () => setState(() => period = p),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.18)
                            : Colors.transparent,
                      ),
                      child: Text(
                        '${p}M',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.textPrimary
                              : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GlassCard(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxMonthValue * 1.1,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 || index >= displayedMonths.length) {
                          return const SizedBox.shrink();
                        }
                        final m = displayedMonths[index];
                        final isLast = index == displayedMonths.length - 1;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            m['label'] as String,
                            style: TextStyle(
                              color: isLast
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 9,
                              fontWeight:
                                  isLast ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(displayedMonths.length, (index) {
                  final m = displayedMonths[index];
                  final value = m['value'] as double;
                  final isLast = index == displayedMonths.length - 1;
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        width: 22,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        gradient: isLast
                            ? AppColors.brandGradient
                            : LinearGradient(
                                colors: [
                                  Colors.white.withValues(alpha: 0.14),
                                  Colors.white.withValues(alpha: 0.14),
                                ],
                              ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDonutSection(List<_CategoryData> categories, double totalExpenses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gasto por categoria',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              SizedBox(
                width: 140,
                height: 140,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 35,
                    sections: categories.map((cat) {
                      return PieChartSectionData(
                        value: cat.percent.toDouble(),
                        color: cat.color,
                        radius: 16,
                        title: '',
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ...categories.map((cat) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: cat.color,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Text(
                          '${cat.percent}%',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatBRL(cat.amount),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingSection(List<Bill> ranking) {
    if (ranking.isEmpty) return const SizedBox.shrink();

    final maxAmount = ranking.first.amount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Maiores gastos do mês',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 15,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        ...ranking.asMap().entries.map((entry) {
          final index = entry.key;
          final bill = entry.value;
          final pct = (bill.amount / maxAmount) * 100;

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.10),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    child: const Icon(
                      Icons.receipt_long,
                      size: 17,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          bill.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: pct / 100,
                            backgroundColor: Colors.white.withValues(alpha: 0.08),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.negative,
                            ),
                            minHeight: 4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _formatBRL(bill.amount),
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _formatBRL(double value) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }
}

class _CategoryData {
  final String name;
  final int percent;
  final double amount;
  final Color color;

  const _CategoryData(this.name, this.percent, this.amount, this.color);
}

class _InsightCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _InsightCard({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: color.withValues(alpha: 0.15),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
