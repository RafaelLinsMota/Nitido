import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/models/models.dart';
import '../../core/services/budgets_service.dart';
import '../../core/providers/providers.dart';
import '../../shared/widgets/glass_widgets.dart';
import '../../core/theme/app_theme.dart';

class BudgetsScreen extends ConsumerStatefulWidget {
  const BudgetsScreen({super.key});

  @override
  ConsumerState<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends ConsumerState<BudgetsScreen> {
  final _monthController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _selectedMonth = DateTime.now();
  String? _selectedCategoryId;
  List<Budget> _budgets = [];
  Map<String, Map<String, dynamic>> _categorySpending = {};

  static const _fallbackCategories = [
    {'id': '550e8400-e29b-41d4-a716-446655440001', 'name': 'Moradia'},
    {'id': '550e8400-e29b-41d4-a716-446655440002', 'name': 'Alimentação'},
    {'id': '550e8400-e29b-41d4-a716-446655440003', 'name': 'Transporte'},
    {'id': '550e8400-e29b-41d4-a716-446655440004', 'name': 'Lazer'},
    {'id': '550e8400-e29b-41d4-a716-446655440005', 'name': 'Saúde'},
    {'id': '550e8400-e29b-41d4-a716-446655440008', 'name': 'Outros'},
  ];

  String _formatBRL(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  @override
  void initState() {
    super.initState();
    _monthController.text = DateFormat('MM/yyyy').format(_selectedMonth);
    _loadBudgetData();
  }

  @override
  void dispose() {
    _monthController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getDisplayCategories(List<Category> dbCategories) {
    if (dbCategories.isNotEmpty) {
      return dbCategories.map((c) => {'id': c.id, 'name': c.name}).toList();
    }
    return _fallbackCategories;
  }

  Future<void> _loadBudgetData() async {
    final userId = ref.read(currentUserProvider)?.id;
    if (userId != null) {
      final budgets = await BudgetsService.getBudgetsForMonth(userId, _selectedMonth);
      final spending = await BudgetsService.getCategorySpending(userId, _selectedMonth);
      setState(() {
        _budgets = budgets;
        _categorySpending = spending;
      });
    }
  }

  Future<void> _saveBudget() async {
    if (_selectedCategoryId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecione uma categoria')),
        );
      }
      return;
    }

    final amountText = _amountController.text.replaceAll(',', '.');
    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Insira um valor válido')),
        );
      }
      return;
    }

    final userId = ref.read(currentUserProvider)?.id;
    if (userId == null) return;

    try {
      await BudgetsService.createOrUpdateBudget(
        userId: userId,
        categoryId: _selectedCategoryId!,
        amount: amount,
        month: _selectedMonth,
      );
      _amountController.clear();
      setState(() => _selectedCategoryId = null);
      await _loadBudgetData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Orçamento salvo com sucesso!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao salvar: $e')),
        );
      }
    }
  }

  Future<void> _deleteBudget(String budgetId) async {
    await BudgetsService.deleteBudget(budgetId);
    await _loadBudgetData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orçamento excluído!')),
      );
    }
  }

  Future<void> _resetMonth() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1A2E),
        title: const Text('Zerar mês', style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Isso irá excluir todos os orçamentos, contas e receitas de ${_monthController.text}. Deseja continuar?',
          style: const TextStyle(color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Zerar', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final userId = ref.read(currentUserProvider)?.id;
      if (userId != null) {
        await BudgetsService.resetMonth(userId, _selectedMonth);
        await _loadBudgetData();
        ref.invalidate(billsProvider);
        ref.invalidate(incomesProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Mês zerado com sucesso!')),
          );
        }
      }
    }
  }

  String _getCategoryName(String categoryId, List<Map<String, dynamic>> displayCategories) {
    final cat = displayCategories.where((c) => c['id'] == categoryId);
    return cat.isNotEmpty ? cat.first['name'] as String : 'Sem categoria';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Orçamentos'),
      ),
      body: Consumer(builder: (context, ref, _) {
        final categoriesAsync = ref.watch(categoriesProvider);
        final displayCategories = categoriesAsync.when(
          data: (list) => _getDisplayCategories(list),
          loading: () => _fallbackCategories,
          error: (_, __) => _fallbackCategories,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _selectedMonth,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _selectedMonth = pickedDate;
                      _monthController.text = DateFormat('MM/yyyy').format(pickedDate);
                    });
                    await _loadBudgetData();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: Colors.white.withValues(alpha: 0.06),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      Text(
                        _monthController.text,
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white.withValues(alpha: 0.06),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategoryId,
                    hint: const Text('Selecionar categoria', style: TextStyle(color: AppColors.textSecondary)),
                    dropdownColor: const Color(0xFF241E36),
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                    iconEnabledColor: AppColors.textSecondary,
                    items: displayCategories.map((cat) {
                      return DropdownMenuItem<String>(
                        value: cat['id'] as String,
                        child: Text(cat['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  labelText: 'Valor do Orçamento',
                  labelStyle: const TextStyle(color: AppColors.textSecondary),
                  prefixText: 'R\$ ',
                  prefixStyle: const TextStyle(color: AppColors.textSecondary),
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
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveBudget,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    backgroundColor: AppColors.violet,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Salvar Orçamento'),
                ),
              ),
              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _resetMonth,
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  label: const Text('Zerar Mês'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    side: const BorderSide(color: AppColors.negative),
                    foregroundColor: AppColors.negative,
                  ),
                ),
              ),
              const SizedBox(height: 32),

              const Text(
                'Orçamentos Atuais',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _buildBudgetsList(displayCategories),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildBudgetsList(List<Map<String, dynamic>> displayCategories) {
    if (_budgets.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Nenhum orçamento encontrado para este mês.',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _budgets.length,
      itemBuilder: (context, index) {
        final budget = _budgets[index];
        final categoryName = _getCategoryName(budget.categoryId, displayCategories);

        final spendingData = _categorySpending[budget.categoryId];
        final spentAmount = (spendingData?['amount'] as double?) ?? 0.0;
        final budgetAmount = budget.amount;
        final remainingAmount = budgetAmount - spentAmount;
        final isOverBudget = remainingAmount < 0;
        final progress = budgetAmount > 0 ? (spentAmount / budgetAmount).clamp(0.0, 1.0) : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        categoryName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isOverBudget)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.negative.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Excedido',
                          style: TextStyle(color: AppColors.negative, fontSize: 10, fontWeight: FontWeight.w700),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOverBudget ? AppColors.negative : AppColors.violet,
                    ),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Gasto: ${_formatBRL(spentAmount)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                    Text('Limite: ${_formatBRL(budgetAmount)}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  isOverBudget
                      ? 'Ultrapassou em ${_formatBRL(remainingAmount.abs())}'
                      : 'Restante: ${_formatBRL(remainingAmount)}',
                  style: TextStyle(
                    color: isOverBudget ? AppColors.negative : AppColors.positive,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 18),
                      color: AppColors.textSecondary,
                      onPressed: () {
                        setState(() {
                          _selectedCategoryId = budget.categoryId;
                          _amountController.text = budget.amount.toString();
                        });
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, size: 18),
                      color: AppColors.negative,
                      onPressed: () => _deleteBudget(budget.id),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
