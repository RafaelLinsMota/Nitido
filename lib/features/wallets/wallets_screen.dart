import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:nitido/core/theme/app_theme.dart';
import 'package:nitido/core/providers/providers.dart';
import 'package:nitido/core/models/models.dart';
import 'package:nitido/core/services/wallets_service.dart';
import 'package:nitido/shared/widgets/glass_widgets.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletsProvider);
    final selectedWallet = ref.watch(selectedWalletProvider);

    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async => ref.invalidate(walletsProvider),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 160),
                      children: [
                        const Text(
                          'Carteiras',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildTotalBalanceCard(wallets),
                        const SizedBox(height: 18),
                        _buildWalletsList(wallets, selectedWallet),
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
              onPressed: () => _showNewWalletSheet(),
              isOpen: false,
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

  Widget _buildTotalBalanceCard(AsyncValue<List<Wallet>> wallets) {
    return wallets.when(
      data: (list) {
        final total = WalletsService.getTotalBalanceSync(list);
        return GlassCard(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Saldo total',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Text(
                _formatBRL(total),
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${list.length} ${list.length == 1 ? 'conta' : 'contas'}',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const GlassCard(
        padding: EdgeInsets.all(22),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => GlassCard(
        padding: const EdgeInsets.all(22),
        child: Text('Erro: $e', style: const TextStyle(color: AppColors.negative)),
      ),
    );
  }

  Widget _buildWalletsList(AsyncValue<List<Wallet>> wallets, Wallet? selected) {
    return wallets.when(
      data: (list) {
        if (list.isEmpty) {
          return GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(Icons.account_balance_wallet_outlined,
                    size: 48, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                const SizedBox(height: 14),
                const Text(
                  'Nenhuma carteira criada',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Adicione suas contas para\norganizar suas finanças',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _showNewWalletSheet,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      gradient: AppColors.brandGradient,
                    ),
                    child: const Text(
                      'Criar primeira carteira',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Suas carteiras',
              style: TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            ...list.map((wallet) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _buildWalletCard(wallet, wallet.id == selected?.id),
                )),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, _) => Text('Erro: $e', style: const TextStyle(color: AppColors.negative)),
    );
  }

  Widget _buildWalletCard(Wallet wallet, bool isSelected) {
    final walletColor = _parseColor(wallet.color);

    return GestureDetector(
      onTap: () {
        ref.read(selectedWalletIdProvider.notifier).state =
            isSelected ? null : wallet.id;
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
            color: isSelected ? walletColor : AppColors.glassBorder,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    walletColor.withValues(alpha: isSelected ? 0.2 : 0.1),
                    Colors.white.withValues(alpha: 0.03),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          color: walletColor.withValues(alpha: 0.2),
                        ),
                        child: Icon(_getWalletIcon(wallet.type),
                            size: 20, color: walletColor),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    wallet.name,
                                    style: const TextStyle(
                                      fontFamily: 'Manrope',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                if (wallet.isDefault)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: AppColors.teal.withValues(alpha: 0.2),
                                    ),
                                    child: const Text(
                                      'Principal',
                                      style: TextStyle(
                                        color: AppColors.teal,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              wallet.typeName,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Saldo',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        _formatBRL(wallet.balance),
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (isSelected) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showEditWalletSheet(wallet),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: Colors.white.withValues(alpha: 0.08),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit, size: 14, color: AppColors.textSecondary),
                                  SizedBox(width: 6),
                                  Text(
                                    'Editar',
                                    style: TextStyle(
                                      color: AppColors.textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _confirmDelete(wallet),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                color: AppColors.negative.withValues(alpha: 0.15),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.delete_outline, size: 14, color: AppColors.negative),
                                  SizedBox(width: 6),
                                  Text(
                                    'Excluir',
                                    style: TextStyle(
                                      color: AppColors.negative,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showNewWalletSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletFormSheet(
        onSave: (name, type, color, icon) async {
          await WalletsService.createWallet(
            name: name,
            type: type,
            color: color,
            icon: icon,
            isDefault: false,
          );
          ref.invalidate(walletsProvider);
        },
      ),
    );
  }

  void _showEditWalletSheet(Wallet wallet) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WalletFormSheet(
        initialName: wallet.name,
        initialType: wallet.type,
        initialColor: wallet.color,
        onSave: (name, type, color, icon) async {
          await WalletsService.updateWallet(wallet.id, {
            'name': name,
            'type': type.name,
            'color': color,
            'icon': icon,
          });
          ref.invalidate(walletsProvider);
        },
      ),
    );
  }

  void _confirmDelete(Wallet wallet) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1629),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Excluir carteira?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: Text(
          'Deseja excluir "${wallet.name}"? Os lançamentos vinculados perderão a referência.',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await WalletsService.deleteWallet(wallet.id);
              ref.invalidate(walletsProvider);
              if (ref.read(selectedWalletIdProvider) == wallet.id) {
                ref.read(selectedWalletIdProvider.notifier).state = null;
              }
            },
            child: const Text('Excluir', style: TextStyle(color: AppColors.negative)),
          ),
        ],
      ),
    );
  }

  Color _parseColor(String hex) {
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

  String _formatBRL(double value) {
    final formatter = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    return formatter.format(value);
  }
}

class _WalletFormSheet extends ConsumerStatefulWidget {
  final String? initialName;
  final WalletType? initialType;
  final String? initialColor;
  final Future<void> Function(String name, WalletType type, String color, String icon) onSave;

  const _WalletFormSheet({
    this.initialName,
    this.initialType,
    this.initialColor,
    required this.onSave,
  });

  @override
  ConsumerState<_WalletFormSheet> createState() => _WalletFormSheetState();
}

class _WalletFormSheetState extends ConsumerState<_WalletFormSheet> {
  late TextEditingController nameController;
  late WalletType selectedType;
  late String selectedColor;
  bool isLoading = false;

  final walletColors = [
    '#6C63FF',
    '#14B8A6',
    '#FB7185',
    '#FBBF24',
    '#38BDF8',
    '#A78BFA',
    '#34D399',
    '#FB923C',
  ];

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.initialName ?? '');
    selectedType = widget.initialType ?? WalletType.conta_corrente;
    selectedColor = widget.initialColor ?? '#6C63FF';
  }

  @override
  void dispose() {
    nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.65,
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
                  Text(
                    widget.initialName != null ? 'Editar carteira' : 'Nova carteira',
                    style: const TextStyle(
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
              const SizedBox(height: 24),
              const _FieldLabel('Nome'),
              TextField(
                controller: nameController,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Ex: Nubank, Itaú, Carteira...',
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
              const _FieldLabel('Tipo'),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: Colors.white.withValues(alpha: 0.06),
                ),
                child: Row(
                  children: WalletType.values.map((type) {
                    final isSelected = selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => selectedType = type),
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
                            _walletTypeLabel(type),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isSelected
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
              const _FieldLabel('Cor'),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: walletColors.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final colorHex = walletColors[index];
                    final isSelected = selectedColor == colorHex;
                    final color = _parseColor(colorHex);
                    return GestureDetector(
                      onTap: () => setState(() => selectedColor = colorHex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: color,
                          border: Border.all(
                            color: isSelected ? Colors.white : Colors.transparent,
                            width: 3,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.5),
                                    blurRadius: 12,
                                  )
                                ]
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading || nameController.text.trim().isEmpty
                      ? null
                      : _handleSubmit,
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
                      gradient: AppColors.brandGradient,
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
                              widget.initialName != null ? 'Salvar alterações' : 'Criar carteira',
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
    setState(() => isLoading = true);
    try {
      final icon = _getWalletIconName(selectedType);
      await widget.onSave(
        nameController.text.trim(),
        selectedType,
        selectedColor,
        icon,
      );
      if (mounted) Navigator.pop(context);
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

  String _getWalletIconName(WalletType type) {
    switch (type) {
      case WalletType.conta_corrente:
        return 'account_balance';
      case WalletType.poupanca:
        return 'savings';
      case WalletType.carteira:
        return 'account_balance_wallet';
      case WalletType.credito:
        return 'credit_card';
    }
  }

  String _walletTypeLabel(WalletType type) {
    switch (type) {
      case WalletType.conta_corrente:
        return 'Conta';
      case WalletType.poupanca:
        return 'Poup.';
      case WalletType.carteira:
        return 'Carteira';
      case WalletType.credito:
        return 'Crédito';
    }
  }

  Color _parseColor(String hex) {
    hex = hex.replaceFirst('#', '');
    if (hex.length == 6) hex = 'FF$hex';
    return Color(int.parse(hex, radix: 16));
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
