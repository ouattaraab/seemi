import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

/// Écran de connexion — email ou téléphone + mot de passe.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl   = TextEditingController();

  bool _obscurePassword = true;
  bool _acceptedTerms   = false;

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez accepter les termes et conditions.'),
          backgroundColor: AppColors.kError,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.login(
      emailOrPhone: _identifierCtrl.text.trim(),
      password:     _passwordCtrl.text,
    );

    if (!mounted) return;
    if (success) {
      context.go(RouteNames.kRouteHome);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        return Scaffold(
          backgroundColor: AppColors.kBgBase,
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.kScreenMargin,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Hero ──────────────────────────────────────────────
                    _buildHero(),
                    const SizedBox(height: AppSpacing.kSpace2xl),

                    // ── Champ identifiant ─────────────────────────────────
                    _PillField(
                      controller: _identifierCtrl,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Email ou numéro de téléphone',
                      prefixIcon: Icons.person_outline_rounded,
                      onChanged: (_) => authProvider.clearError(),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Veuillez entrer votre email ou téléphone'
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // ── Champ mot de passe ────────────────────────────────
                    _PillField(
                      controller: _passwordCtrl,
                      hintText: 'Mot de passe',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.kTextSecondary,
                          size: 20,
                        ),
                        onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                      ),
                      onChanged: (_) => authProvider.clearError(),
                      validator: (v) => (v == null || v.isEmpty)
                          ? 'Veuillez entrer votre mot de passe'
                          : null,
                    ),

                    // ── Mot de passe oublié ───────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        child: Text(
                          'Mot de passe oublié ?',
                          style: AppTextStyles.kCaption.copyWith(
                            color: AppColors.kPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),

                    // ── CGU ───────────────────────────────────────────────
                    _buildTermsRow(),

                    // ── Erreur API ────────────────────────────────────────
                    if (authProvider.error != null) ...[
                      const SizedBox(height: AppSpacing.kSpaceSm),
                      _ErrorBanner(message: authProvider.error!),
                    ],

                    const SizedBox(height: AppSpacing.kSpaceLg),

                    // ── Bouton connexion ──────────────────────────────────
                    SizedBox(
                      height: AppSpacing.kButtonHeight,
                      child: FilledButton(
                        onPressed: authProvider.isLoading ? null : _onLogin,
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                          elevation: 6,
                          shadowColor:
                              AppColors.kPrimary.withValues(alpha: 0.30),
                        ),
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Se connecter',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.kSpaceLg),

                    // ── Inscription ───────────────────────────────────────
                    _buildRegisterLink(),

                    const SizedBox(height: AppSpacing.kSpace2xl),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── Hero ────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.kSpaceXl),

        // Logo avec halo décoratif
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orbe amber (outer glow)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.kAccent.withValues(alpha: 0.10),
                  ),
                ),
                // Orbe primary (inner glow)
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.kPrimary.withValues(alpha: 0.08),
                  ),
                ),
                // Logo
                ClipOval(
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: Image.asset(
                      'assets/images/logo_seemi.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        color: AppColors.kPrimary,
                        child: const Icon(
                          Icons.visibility_rounded,
                          color: Colors.white,
                          size: 36,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Marque
        const Text(
          'SeeMi',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.kTextPrimary,
            letterSpacing: -0.5,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        Text(
          'Connectez-vous à votre compte.',
          style: AppTextStyles.kBodyMedium.copyWith(
            color: AppColors.kTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── CGU ─────────────────────────────────────────────────────────────────

  Widget _buildTermsRow() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: _acceptedTerms,
            onChanged: (v) =>
                setState(() => _acceptedTerms = v ?? false),
            activeColor: AppColors.kPrimary,
            checkColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6)),
            side: const BorderSide(color: AppColors.kBorder, width: 1.5),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            onTap: () =>
                setState(() => _acceptedTerms = !_acceptedTerms),
            child: RichText(
              text: TextSpan(
                style: AppTextStyles.kCaption.copyWith(
                  color: AppColors.kTextSecondary,
                ),
                children: [
                  const TextSpan(text: "J'accepte les "),
                  const TextSpan(
                    text: 'termes et conditions',
                    style: TextStyle(
                      color: AppColors.kPrimary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  const TextSpan(text: " d'utilisation de SeeMi."),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Lien inscription ────────────────────────────────────────────────────

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Pas encore de compte ?',
          style: AppTextStyles.kBodyMedium.copyWith(
            color: AppColors.kTextSecondary,
          ),
        ),
        TextButton(
          onPressed: () => context.go(RouteNames.kRouteRegister),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            "S'inscrire",
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.kPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── _PillField ───────────────────────────────────────────────────────────────

class _PillField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;

  const _PillField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      onChanged: onChanged,
      validator: validator,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.kTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 15,
          color: AppColors.kTextTertiary,
        ),
        filled: true,
        fillColor: AppColors.kBgSurface,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(prefixIcon,
              color: AppColors.kTextSecondary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide:
              const BorderSide(color: AppColors.kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide:
              const BorderSide(color: AppColors.kError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide:
              const BorderSide(color: AppColors.kError, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 18),
      ),
    );
  }
}

// ─── _ErrorBanner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.kError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kError.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.kError, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.kCaption
                  .copyWith(color: AppColors.kError),
            ),
          ),
        ],
      ),
    );
  }
}
