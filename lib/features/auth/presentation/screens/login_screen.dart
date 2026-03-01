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
  final _formKey          = GlobalKey<FormState>();
  final _identifierCtrl   = TextEditingController();
  final _passwordCtrl     = TextEditingController();

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
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.kScreenMargin,
                vertical: AppSpacing.kSpaceLg,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.kSpaceXl),

                    // Logo + Titre
                    Center(
                      child: Image.asset(
                        'assets/images/logo_seemi.png',
                        width: 80,
                        height: 80,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.visibility,
                          size: 80,
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),
                    const Text(
                      'Connexion',
                      style: AppTextStyles.kHeadlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.kSpaceSm),
                    Text(
                      'Connectez-vous à votre compte SeeMi.',
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: AppColors.kTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.kSpace2xl),

                    // Email ou téléphone
                    TextFormField(
                      controller: _identifierCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email ou numéro de téléphone',
                        hintText: 'exemple@email.com ou +2250101181686',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      onChanged: (_) {
                        if (authProvider.error != null) {
                          authProvider.clearError();
                        }
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Veuillez entrer votre email ou téléphone';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // Mot de passe
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        hintText: 'Votre mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      onChanged: (_) {
                        if (authProvider.error != null) {
                          authProvider.clearError();
                        }
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Veuillez entrer votre mot de passe';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // Termes et conditions
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          onChanged: (v) =>
                              setState(() => _acceptedTerms = v ?? false),
                          activeColor: AppColors.kPrimary,
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(
                                () => _acceptedTerms = !_acceptedTerms),
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.kCaption.copyWith(
                                  color: AppColors.kTextSecondary,
                                ),
                                children: [
                                  const TextSpan(text: "J'accepte les "),
                                  TextSpan(
                                    text: 'termes et conditions',
                                    style: AppTextStyles.kCaption.copyWith(
                                      color: AppColors.kPrimary,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(
                                      text: ' d\'utilisation de SeeMi.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    // Erreur API
                    if (authProvider.error != null) ...[
                      const SizedBox(height: AppSpacing.kSpaceSm),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.kSpaceSm),
                        decoration: BoxDecoration(
                          color: AppColors.kError.withAlpha(26),
                          borderRadius: BorderRadius.circular(
                              AppSpacing.kRadiusButton),
                          border: Border.all(
                              color: AppColors.kError.withAlpha(77)),
                        ),
                        child: Text(
                          authProvider.error!,
                          style: AppTextStyles.kCaption
                              .copyWith(color: AppColors.kError),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],

                    const SizedBox(height: AppSpacing.kSpaceLg),

                    // Bouton Connexion
                    SizedBox(
                      height: AppSpacing.kSpace2xl,
                      child: FilledButton(
                        onPressed: authProvider.isLoading ? null : _onLogin,
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: AppSpacing.kSpaceLg,
                                height: AppSpacing.kSpaceLg,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.kTextPrimary,
                                ),
                              )
                            : const Text('Se connecter'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // Lien inscription
                    Center(
                      child: TextButton(
                        onPressed: () =>
                            context.go(RouteNames.kRouteRegister),
                        child: Text(
                          "Pas encore de compte ? S'inscrire",
                          style: AppTextStyles.kBodyMedium
                              .copyWith(color: AppColors.kPrimary),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.kSpaceLg),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
