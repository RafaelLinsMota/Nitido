import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitido/core/theme/app_theme.dart';
import 'package:nitido/core/providers/providers.dart';
import 'package:nitido/core/services/auth_service.dart';
import 'package:nitido/shared/widgets/glass_widgets.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      body: Stack(
        children: [
          _buildBackgroundBlobs(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              children: [
                const Text(
                  'Perfil',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                user.when(
                  data: (profile) => _buildUserInfo(profile?.name ?? 'Usuário', profile?.email ?? ''),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.teal),
                  ),
                  error: (_, __) => const Text(
                    'Erro ao carregar perfil',
                    style: TextStyle(color: AppColors.negative),
                  ),
                ),
                const SizedBox(height: 24),
                _buildSection(
                  title: 'Conta',
                  items: [
                    _MenuItem(icon: Icons.person_outline, label: 'Editar perfil'),
                    _MenuItem(icon: Icons.category_outlined, label: 'Categorias personalizadas'),
                    _MenuItem(icon: Icons.notifications_outlined, label: 'Notificações'),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Aparência',
                  items: [
                    _MenuItem(icon: Icons.dark_mode_outlined, label: 'Modo escuro', trailing: Switch(
                      value: true,
                      onChanged: (_) {},
                      activeColor: AppColors.positive,
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                _buildSection(
                  title: 'Sobre',
                  items: [
                    _MenuItem(icon: Icons.info_outline, label: 'Sobre o Nítido'),
                    _MenuItem(icon: Icons.star_outline, label: 'Avaliar o app'),
                    _MenuItem(icon: Icons.privacy_tip_outlined, label: 'Política de privacidade'),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () async {
                      await AuthService.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacementNamed('/auth');
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: const BorderSide(color: AppColors.negative),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Sair da conta',
                      style: TextStyle(
                        color: AppColors.negative,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

  Widget _buildUserInfo(String name, String email) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ],
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w600,
            fontSize: 12,
            color: AppColors.textSecondary,
            textBaseline: TextBaseline.alphabetic,
          ),
        ),
        const SizedBox(height: 8),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  item,
                  if (index < items.length - 1)
                    Divider(
                      height: 1,
                      indent: 52,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? trailing;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.textSecondary),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
              ),
            ),
          ),
          if (trailing != null)
            trailing!
          else
            Icon(Icons.chevron_right, size: 16, color: AppColors.textSecondary),
        ],
      ),
    );
  }
}
