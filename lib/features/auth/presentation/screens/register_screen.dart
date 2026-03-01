import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';

/// Écran d'inscription — email + mot de passe.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey             = GlobalKey<FormState>();
  final _firstNameCtrl       = TextEditingController();
  final _lastNameCtrl        = TextEditingController();
  final _phoneCtrl           = TextEditingController();
  final _emailCtrl           = TextEditingController();
  final _dobCtrl             = TextEditingController();
  final _passwordCtrl        = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();

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
      setState(() {
        _dobCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
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
          backgroundColor: AppColors.kBgBase,
          body: SafeArea(
            child: Column(
              children: [
                // ── App bar ────────────────────────────────────────────────
                _buildAppBar(),

                // ── Form ──────────────────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.kScreenMargin,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Header compact
                          _buildHeader(),
                          const SizedBox(height: AppSpacing.kSpaceXl),

                          // ── Section Identité ──
                          const _SectionLabel('Identité'),
                          const SizedBox(height: 12),

                          // Prénom + Nom (côte à côte)
                          Row(
                            children: [
                              Expanded(
                                child: _PillField(
                                  controller: _firstNameCtrl,
                                  hintText: 'Prénom',
                                  prefixIcon: Icons.badge_outlined,
                                  onChanged: (_) => authProvider.clearError(),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Requis'
                                      : null,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.kSpaceSm),
                              Expanded(
                                child: _PillField(
                                  controller: _lastNameCtrl,
                                  hintText: 'Nom',
                                  prefixIcon: Icons.badge_outlined,
                                  onChanged: (_) => authProvider.clearError(),
                                  validator: (v) => (v == null || v.trim().isEmpty)
                                      ? 'Requis'
                                      : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.kSpaceMd),

                          // Date de naissance
                          _DateField(
                            controller: _dobCtrl,
                            onTap: _pickDate,
                          ),

                          const SizedBox(height: AppSpacing.kSpaceXl),

                          // ── Section Contact ──
                          const _SectionLabel('Contact'),
                          const SizedBox(height: 12),

                          // Téléphone avec préfixe +225
                          _PhoneField(
                            controller: _phoneCtrl,
                            onChanged: (_) => authProvider.clearError(),
                          ),
                          const SizedBox(height: AppSpacing.kSpaceMd),

                          // Email
                          _PillField(
                            controller: _emailCtrl,
                            hintText: 'Adresse email',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => authProvider.clearError(),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Requis';
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Email invalide';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.kSpaceXl),

                          // ── Section Sécurité ──
                          const _SectionLabel('Sécurité'),
                          const SizedBox(height: 12),

                          // Mot de passe
                          _PillField(
                            controller: _passwordCtrl,
                            hintText: 'Mot de passe (min. 8 caractères)',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePassword,
                            onChanged: (_) => authProvider.clearError(),
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
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              if (v.length < 8) return 'Minimum 8 caractères';
                              return null;
                            },
                          ),
                          const SizedBox(height: AppSpacing.kSpaceMd),

                          // Confirmer mot de passe
                          _PillField(
                            controller: _passwordConfirmCtrl,
                            hintText: 'Confirmer le mot de passe',
                            prefixIcon: Icons.lock_outline_rounded,
                            obscureText: _obscurePasswordConfirm,
                            onChanged: (_) => authProvider.clearError(),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePasswordConfirm
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: AppColors.kTextSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() =>
                                  _obscurePasswordConfirm =
                                      !_obscurePasswordConfirm),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Requis';
                              if (v != _passwordCtrl.text) {
                                return 'Les mots de passe ne correspondent pas';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: AppSpacing.kSpaceLg),

                          // ── CGU ──
                          _buildTermsRow(),

                          // ── Erreur API ──
                          if (authProvider.error != null) ...[
                            const SizedBox(height: AppSpacing.kSpaceSm),
                            _ErrorBanner(message: authProvider.error!),
                          ],

                          const SizedBox(height: AppSpacing.kSpaceLg),

                          // ── Bouton inscription ──
                          SizedBox(
                            height: AppSpacing.kButtonHeight,
                            child: FilledButton(
                              onPressed: authProvider.isLoading
                                  ? null
                                  : _onRegister,
                              style: FilledButton.styleFrom(
                                shape: const StadiumBorder(),
                                elevation: 6,
                                shadowColor: AppColors.kPrimary
                                    .withValues(alpha: 0.30),
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
                                  : const Text("S'inscrire"),
                            ),
                          ),

                          const SizedBox(height: AppSpacing.kSpaceLg),

                          // ── Lien connexion ──
                          _buildLoginLink(),

                          const SizedBox(height: AppSpacing.kSpace2xl),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── App bar ──────────────────────────────────────────────────────────────

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.kBgElevated,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.kTextPrimary,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Header compact ───────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Column(
      children: [
        const SizedBox(height: AppSpacing.kSpaceMd),
        // Logo miniature dans halo
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.kAccent.withValues(alpha: 0.10),
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.kPrimary.withValues(alpha: 0.08),
                ),
              ),
              ClipOval(
                child: SizedBox(
                  width: 40,
                  height: 40,
                  child: Image.asset(
                    'assets/images/logo_seemi.png',
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: AppColors.kPrimary,
                      child: const Icon(
                        Icons.visibility_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Créer un compte',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: AppColors.kTextPrimary,
            letterSpacing: -0.3,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        const Text(
          'Rejoignez SeeMi et monétisez vos contenus.',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: AppColors.kTextSecondary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // ─── CGU ─────────────────────────────────────────────────────────────────

  Widget _buildTermsRow() {
    return GestureDetector(
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: _acceptedTerms ? AppColors.kPrimary : Colors.transparent,
              border: Border.all(
                color: _acceptedTerms ? AppColors.kPrimary : AppColors.kBorder,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: _acceptedTerms
                ? const Icon(Icons.check_rounded, size: 13, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: AppColors.kTextSecondary,
                ),
                children: [
                  TextSpan(text: "J'accepte les "),
                  TextSpan(
                    text: 'termes et conditions',
                    style: TextStyle(
                      color: AppColors.kPrimary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  TextSpan(text: " d'utilisation de SeeMi."),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Lien connexion ──────────────────────────────────────────────────────

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Déjà un compte ?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 15,
            color: AppColors.kTextSecondary,
          ),
        ),
        TextButton(
          onPressed: () => context.go(RouteNames.kRouteLogin),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Se connecter',
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

// ─── _SectionLabel ────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 11,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.5,
        color: AppColors.kTextTertiary,
      ),
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

// ─── _DateField ───────────────────────────────────────────────────────────────

class _DateField extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onTap;

  const _DateField({required this.controller, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: onTap,
      style: const TextStyle(
        fontFamily: 'Plus Jakarta Sans',
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.kTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: 'Date de naissance',
        hintStyle: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 15,
          color: AppColors.kTextTertiary,
        ),
        filled: true,
        fillColor: AppColors.kBgSurface,
        prefixIcon: const Padding(
          padding: EdgeInsets.only(left: 16, right: 10),
          child: Icon(Icons.calendar_today_outlined,
              color: AppColors.kTextSecondary, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 48),
        suffixIcon: const Icon(
          Icons.keyboard_arrow_down_rounded,
          color: AppColors.kTextSecondary,
          size: 22,
        ),
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
      validator: (v) =>
          (v == null || v.isEmpty) ? 'Requis' : null,
    );
  }
}

// ─── _PhoneField ──────────────────────────────────────────────────────────────

class _PhoneField extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;

  const _PhoneField({required this.controller, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (v) {
        final text = controller.text;
        if (text.isEmpty) return 'Requis';
        if (text.length < 8) return 'Numéro invalide';
        return null;
      },
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.kBgSurface,
                borderRadius:
                    BorderRadius.circular(AppSpacing.kRadiusPill),
                border: Border.all(
                  color: state.hasError
                      ? AppColors.kError
                      : AppColors.kBorder,
                  width: state.hasError ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  // Préfixe pays
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.phone_outlined,
                            color: AppColors.kTextSecondary, size: 20),
                        SizedBox(width: 8),
                        Text(
                          '+225',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.kTextPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Séparateur vertical
                  Container(
                    width: 1,
                    height: 24,
                    color: AppColors.kBorder,
                  ),
                  // Input
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(10),
                      ],
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: AppColors.kTextPrimary,
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0101181686',
                        hintStyle: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 15,
                          color: AppColors.kTextTertiary,
                        ),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onChanged: (v) {
                        state.didChange(v);
                        onChanged?.call(v);
                      },
                    ),
                  ),
                ],
              ),
            ),
            if (state.hasError)
              Padding(
                padding:
                    const EdgeInsets.only(left: 20, top: 6),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
          ],
        );
      },
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
        border:
            Border.all(color: AppColors.kError.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.kError, size: 18),
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
