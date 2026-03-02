import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
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
    if (success) context.go(RouteNames.kRouteHome);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
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

                    // ── Identifiant ───────────────────────────────────────
                    _PillField(
                      controller: _identifierCtrl,
                      keyboardType: TextInputType.emailAddress,
                      hintText: 'Email ou numéro de téléphone',
                      prefixIcon: Icons.person_outline_rounded,
                      onChanged: (_) => authProvider.clearError(),
                      validator: (v) =>
                          (v == null || v.trim().isEmpty)
                              ? 'Veuillez entrer votre email ou téléphone'
                              : null,
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // ── Mot de passe ──────────────────────────────────────
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
                      validator: (v) =>
                          (v == null || v.isEmpty)
                              ? 'Veuillez entrer votre mot de passe'
                              : null,
                    ),

                    // ── Mot de passe oublié ───────────────────────────────
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => context.push(RouteNames.kRouteForgotPassword),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kPrimary,
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

                    // ── Suggestion créer un compte ────────────────────────
                    if (authProvider.accountNotFound) ...[
                      const SizedBox(height: 8),
                      _buildRegisterNudge(),
                    ],

                    const SizedBox(height: AppSpacing.kSpaceLg),

                    // ── Bouton connexion ──────────────────────────────────
                    SizedBox(
                      height: AppSpacing.kButtonHeight,
                      child: FilledButton(
                        onPressed:
                            authProvider.isLoading ? null : _onLogin,
                        style: FilledButton.styleFrom(
                          shape: const StadiumBorder(),
                          elevation: 6,
                          shadowColor:
                              AppColors.kPrimary.withValues(alpha: 0.30),
                          textStyle: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
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
                            : const Text('Se connecter'),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.kSpaceLg),

                    // ── Lien inscription ──────────────────────────────────
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

  // ─── Hero ─────────────────────────────────────────────────────────────────

  Widget _buildHero() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.kSpaceXl),

        // Logo avec halos décoratifs
        Center(
          child: SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orbe amber (outer)
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.kAccent.withValues(alpha: 0.10),
                  ),
                ),
                // Orbe indigo (inner)
                Container(
                  width: 86,
                  height: 86,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.kPrimary.withValues(alpha: 0.08),
                  ),
                ),
                // Image logo
                ClipOval(
                  child: SizedBox(
                    width: 68,
                    height: 68,
                    child: Image.asset(
                      'assets/images/logo_seemi.png',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
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

        // Wordmark "SeeMi" bicolore
        const Text.rich(
          TextSpan(
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
            children: [
              TextSpan(
                text: 'See',
                style: TextStyle(color: AppColors.kTextPrimary),
              ),
              TextSpan(
                text: 'Mi',
                style: TextStyle(color: AppColors.kAccent),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 8),

        const Text(
          'Connectez-vous à votre compte.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            color: AppColors.kTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── Ligne CGU ────────────────────────────────────────────────────────────

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(top: 1),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _acceptedTerms
                    ? AppColors.kPrimary
                    : Colors.transparent,
                border: Border.all(
                  color: _acceptedTerms
                      ? AppColors.kPrimary
                      : AppColors.kBorder,
                  width: 2,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: _acceptedTerms
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: AppColors.kTextSecondary,
                    height: 1.55,
                  ),
                  children: [
                    TextSpan(text: "J'accepte les "),
                    TextSpan(
                      text: 'termes et conditions',
                      style: TextStyle(
                        color: AppColors.kPrimary,
                        fontWeight: FontWeight.w600,
                        decoration: TextDecoration.underline,
                        decorationColor: AppColors.kPrimary,
                      ),
                    ),
                    TextSpan(text: " d'utilisation de SeeMi."),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Nudge "créer un compte" (accountNotFound) ────────────────────────────

  Widget _buildRegisterNudge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.kPrimary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(
            color: AppColors.kPrimary.withValues(alpha: 0.15)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.kPrimary, size: 16),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Aucun compte avec cet identifiant.',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: AppColors.kPrimary,
              ),
            ),
          ),
          GestureDetector(
            onTap: () => context.go(RouteNames.kRouteRegister),
            child: const Text(
              "S'inscrire →",
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.kPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lien inscription ─────────────────────────────────────────────────────

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Pas encore de compte ?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            color: AppColors.kTextSecondary,
          ),
        ),
        TextButton(
          onPressed: () => context.go(RouteNames.kRouteRegister),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            minimumSize: Size.zero,
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
          child:
              Icon(prefixIcon, color: AppColors.kTextSecondary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide:
              const BorderSide(color: AppColors.kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide:
              const BorderSide(color: AppColors.kError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
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
        border: Border.all(
            color: AppColors.kError.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.kError, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                color: AppColors.kError,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
