import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitido/core/theme/app_theme.dart';
import 'package:nitido/core/services/auth_service.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  bool isLogin = true;
  bool showPassword = false;
  bool showConfirmPassword = false;
  bool acceptedTerms = false;
  bool isLoading = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    setState(() => isLoading = true);

    AuthResult result;
    if (isLogin) {
      result = await AuthService.signIn(
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    } else {
      if (passwordController.text != confirmPasswordController.text) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Senhas não conferem')),
          );
        }
        setState(() => isLoading = false);
        return;
      }

      result = await AuthService.signUp(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );
    }

    setState(() => isLoading = false);

    if (!result.isSuccess && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.error ?? 'Erro ao autenticar')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: -60,
            left: -60,
            width: 220,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.violet,
              ),
              foreground: Decoration(
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
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
              ),
              foreground: Decoration(
                shape: BoxShape.circle,
                color: AppColors.teal.withValues(alpha: 0.4),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 24),
                  _buildLogo(),
                  const SizedBox(height: 28),
                  _buildModeTabs(),
                  const SizedBox(height: 24),
                  _buildForm(),
                  const SizedBox(height: 24),
                  _buildSubmitButton(),
                  if (isLogin) ...[
                    const SizedBox(height: 22),
                    _buildDivider(),
                    const SizedBox(height: 16),
                    _buildBiometricButton(),
                  ],
                  const SizedBox(height: 22),
                  _buildToggleMode(),
                  const SizedBox(height: 18),
                  _buildSecurityBadge(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            gradient: AppColors.brandGradient,
            boxShadow: [
              BoxShadow(
                color: AppColors.violet.withValues(alpha: 0.35),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(Icons.aperture, size: 32, color: Colors.white),
        ),
        const SizedBox(height: 16),
        const Text(
          'Nítido',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w800,
            fontSize: 26,
            color: AppColors.textPrimary,
            letterSpacing: -0.02,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Suas finanças em foco',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildModeTabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: Colors.white.withValues(alpha: 0.06),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ModeTab(
              label: 'Entrar',
              active: isLogin,
              onTap: () => setState(() => isLogin = true),
            ),
          ),
          Expanded(
            child: _ModeTab(
              label: 'Criar conta',
              active: !isLogin,
              onTap: () => setState(() => isLogin = false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      children: [
        if (!isLogin) ...[
          _FieldLabel('Nome'),
          _InputField(
            controller: nameController,
            icon: Icons.person_outline,
            placeholder: 'Seu nome completo',
          ),
          const SizedBox(height: 14),
        ],
        _FieldLabel('E-mail'),
        _InputField(
          controller: emailController,
          icon: Icons.mail_outline,
          placeholder: 'voce@email.com',
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        _FieldLabel('Senha'),
        _InputField(
          controller: passwordController,
          icon: Icons.lock_outline,
          placeholder: 'Mínimo de 8 caracteres',
          obscureText: !showPassword,
          suffixIcon: IconButton(
            icon: Icon(
              showPassword ? Icons.visibility_off : Icons.visibility,
              color: AppColors.textSecondary,
              size: 16,
            ),
            onPressed: () => setState(() => showPassword = !showPassword),
          ),
        ),
        if (!isLogin) ...[
          const SizedBox(height: 14),
          _FieldLabel('Confirmar senha'),
          _InputField(
            controller: confirmPasswordController,
            icon: Icons.lock_outline,
            placeholder: 'Repita a senha',
            obscureText: !showConfirmPassword,
            suffixIcon: IconButton(
              icon: Icon(
                showConfirmPassword ? Icons.visibility_off : Icons.visibility,
                color: AppColors.textSecondary,
                size: 16,
              ),
              onPressed: () =>
                  setState(() => showConfirmPassword = !showConfirmPassword),
            ),
          ),
        ],
        if (isLogin)
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () {},
              child: const Text(
                'Esqueci minha senha',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        if (!isLogin) ...[
          const SizedBox(height: 14),
          GestureDetector(
            onTap: () => setState(() => acceptedTerms = !acceptedTerms),
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    border: acceptedTerms
                        ? null
                        : Border.all(color: Colors.white.withValues(alpha: 0.25)),
                    gradient: acceptedTerms ? AppColors.brandGradient : null,
                  ),
                  child: acceptedTerms
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Li e aceito os Termos de Uso e a Política de Privacidade',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
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
                    isLogin ? 'Entrar' : 'Criar conta',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: Text(
            'ou',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
          ),
        ),
        Expanded(child: Container(height: 1, color: Colors.white.withValues(alpha: 0.1))),
      ],
    );
  }

  Widget _buildBiometricButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.fingerprint, color: AppColors.positive, size: 17),
        label: const Text(
          'Entrar com biometria',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 13),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: Colors.white.withValues(alpha: 0.06),
        ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          isLogin ? 'Não tem conta? ' : 'Já tem conta? ',
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
        GestureDetector(
          onTap: () => setState(() => isLogin = !isLogin),
          child: Text(
            isLogin ? 'Criar agora' : 'Entrar',
            style: const TextStyle(
              color: AppColors.positive,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSecurityBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.lock, size: 11, color: AppColors.textTertiary),
        const SizedBox(width: 6),
        Text(
          'Dados protegidos com criptografia de ponta a ponta',
          style: TextStyle(color: AppColors.textTertiary, fontSize: 10),
        ),
      ],
    );
  }
}

class _ModeTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ModeTab({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: active ? AppColors.brandGradient : null,
          color: active ? null : Colors.transparent,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? AppColors.background : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
            fontSize: 14,
            fontFamily: 'Manrope',
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final IconData icon;
  final String placeholder;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.icon,
    required this.placeholder,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
              decoration: InputDecoration(
                hintText: placeholder,
                hintStyle: const TextStyle(
                  color: AppColors.textTertiary,
                  fontSize: 13,
                ),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon!,
        ],
      ),
    );
  }
}
