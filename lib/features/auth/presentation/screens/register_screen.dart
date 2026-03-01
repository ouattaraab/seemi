import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';

/// Écran d'inscription — email + mot de passe.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey              = GlobalKey<FormState>();
  final _firstNameCtrl        = TextEditingController();
  final _lastNameCtrl         = TextEditingController();
  final _phoneCtrl            = TextEditingController();
  final _emailCtrl            = TextEditingController();
  final _dobCtrl              = TextEditingController();
  final _passwordCtrl         = TextEditingController();
  final _passwordConfirmCtrl  = TextEditingController();

  bool _obscurePassword        = true;
  bool _obscurePasswordConfirm = true;
  bool _acceptedTerms          = false;

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _dobCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year - 13, now.month, now.day),
      helpText: 'Date de naissance',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: Theme.of(context).colorScheme.copyWith(
            primary: AppColors.kPrimary,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      _dobCtrl.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _onRegister() async {
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
    final success = await authProvider.register(
      firstName:            _firstNameCtrl.text.trim(),
      lastName:             _lastNameCtrl.text.trim(),
      phone:                '+225${_phoneCtrl.text.trim()}',
      email:                _emailCtrl.text.trim(),
      dateOfBirth:          _dobCtrl.text.trim(),
      password:             _passwordCtrl.text,
      passwordConfirmation: _passwordConfirmCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      // Accepter les TOS automatiquement (flow simplifié)
      final tosProvider = context.read<TosProvider>();
      await tosProvider.acceptTos('creator');
      if (!mounted) return;
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
                    // Logo + Titre
                    Center(
                      child: Image.asset(
                        'assets/images/logo_seemi.png',
                        width: 72,
                        height: 72,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.visibility,
                          size: 72,
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),
                    const Text(
                      'Créer un compte',
                      style: AppTextStyles.kHeadlineLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.kSpaceSm),
                    Text(
                      'Rejoignez SeeMi et commencez à monétiser vos contenus.',
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: AppColors.kTextSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.kSpaceXl),

                    // Nom et Prénoms (ligne)
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            controller: _firstNameCtrl,
                            label: 'Prénom',
                            hint: 'Jean',
                            icon: Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Requis'
                                : null,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.kSpaceSm),
                        Expanded(
                          child: _buildField(
                            controller: _lastNameCtrl,
                            label: 'Nom',
                            hint: 'Dupont',
                            icon: Icons.person_outline,
                            validator: (v) => v == null || v.isEmpty
                                ? 'Requis'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // Téléphone
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone',
                        hintText: '0101181686',
                        prefixIcon: const Icon(Icons.phone_outlined),
                        prefix: Text(
                          '+225 ',
                          style: AppTextStyles.kBodyMedium.copyWith(
                            color: AppColors.kTextSecondary,
                          ),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (v.length < 8) return 'Numéro invalide';
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // Email
                    _buildField(
                      controller: _emailCtrl,
                      label: 'Adresse email',
                      hint: 'exemple@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (!v.contains('@') || !v.contains('.')) {
                          return 'Email invalide';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // Date de naissance
                    TextFormField(
                      controller: _dobCtrl,
                      readOnly: true,
                      onTap: _pickDate,
                      decoration: const InputDecoration(
                        labelText: 'Date de naissance',
                        hintText: 'JJ/MM/AAAA',
                        prefixIcon: Icon(Icons.calendar_today_outlined),
                        suffixIcon: Icon(Icons.arrow_drop_down),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Requis' : null,
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // Mot de passe
                    TextFormField(
                      controller: _passwordCtrl,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        hintText: 'Minimum 8 caractères',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (v.length < 8) {
                          return 'Minimum 8 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // Confirmer mot de passe
                    TextFormField(
                      controller: _passwordConfirmCtrl,
                      obscureText: _obscurePasswordConfirm,
                      decoration: InputDecoration(
                        labelText: 'Confirmer le mot de passe',
                        hintText: 'Répétez votre mot de passe',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePasswordConfirm
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: () => setState(() =>
                              _obscurePasswordConfirm =
                                  !_obscurePasswordConfirm),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Requis';
                        if (v != _passwordCtrl.text) {
                          return 'Les mots de passe ne correspondent pas';
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
                            onTap: () =>
                                setState(() => _acceptedTerms = !_acceptedTerms),
                            child: RichText(
                              text: TextSpan(
                                style: AppTextStyles.kCaption.copyWith(
                                  color: AppColors.kTextSecondary,
                                ),
                                children: [
                                  const TextSpan(
                                      text: "J'accepte les "),
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

                    // Bouton Inscription
                    SizedBox(
                      height: AppSpacing.kSpace2xl,
                      child: FilledButton(
                        onPressed: authProvider.isLoading ? null : _onRegister,
                        child: authProvider.isLoading
                            ? const SizedBox(
                                width: AppSpacing.kSpaceLg,
                                height: AppSpacing.kSpaceLg,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.kTextPrimary,
                                ),
                              )
                            : const Text('S\'inscrire'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),

                    // Lien connexion
                    Center(
                      child: TextButton(
                        onPressed: () => context.go(RouteNames.kRouteLogin),
                        child: Text(
                          'Déjà un compte ? Se connecter',
                          style: AppTextStyles.kBodyMedium
                              .copyWith(color: AppColors.kPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
      validator: validator,
    );
  }
}
