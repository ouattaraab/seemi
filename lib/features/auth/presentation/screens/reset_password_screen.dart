import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/auth/data/auth_remote_datasource.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

/// Écran de réinitialisation de mot de passe, ouvert via deep link.
/// Reçoit [token] et [email] depuis les query params du lien :
/// seemi://reset-password?token=XXX&email=YYY
///
/// Pré-valide le token au chargement pour informer immédiatement l'utilisateur
/// si le lien est déjà utilisé ou expiré, sans qu'il ait à remplir le formulaire.
class ResetPasswordScreen extends StatefulWidget {
  final String token;
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.token,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

enum _TokenState { checking, valid, invalidUsed, expired }

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _passwordCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _success         = false;

  _TokenState _tokenState = _TokenState.checking;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkToken());
  }

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  /// Pré-valide le token dès l'ouverture de l'écran.
  /// L'utilisateur voit immédiatement si le lien est valide ou non.
  Future<void> _checkToken() async {
    try {
      await context.read<AuthProvider>().checkResetToken(
        email: widget.email,
        token: widget.token,
      );
      if (mounted) setState(() => _tokenState = _TokenState.valid);
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _tokenState = e.code == 'EXPIRED_RESET_TOKEN'
            ? _TokenState.expired
            : _TokenState.invalidUsed;
      });
    } catch (_) {
      // Erreur réseau : on laisse accéder au formulaire, le backend re-validera à la soumission
      if (mounted) setState(() => _tokenState = _TokenState.valid);
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final ok = await provider.resetPassword(
      email:                widget.email,
      token:                widget.token,
      password:             _passwordCtrl.text,
      passwordConfirmation: _confirmCtrl.text,
    );

    if (!mounted) return;
    if (ok) {
      setState(() => _success = true);
    } else if (provider.error != null &&
        (provider.error!.contains('expiré') || provider.error!.contains('invalide') || provider.error!.contains('utilisé'))) {
      // Token consommé ou expiré entre la pré-validation et la soumission
      setState(() => _tokenState = _TokenState.invalidUsed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.kTextPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Nouveau mot de passe',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.kTextPrimary,
          ),
        ),
      ),
      body: switch (_tokenState) {
        _TokenState.checking  => const Center(child: CircularProgressIndicator(color: AppColors.kPrimary)),
        _TokenState.expired   => _buildInvalidState(isExpired: true),
        _TokenState.invalidUsed => _buildInvalidState(isExpired: false),
        _TokenState.valid => _success ? _buildSuccess() : _buildForm(),
      },
    );
  }

  /// Formulaire de saisie du nouveau mot de passe.
  Widget _buildForm() {
    return Consumer<AuthProvider>(
      builder: (context, provider, _) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                const Icon(Icons.lock_outlined, size: 64, color: AppColors.kPrimary),
                const SizedBox(height: 24),
                const Text(
                  'Choisissez un nouveau\nmot de passe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.kTextPrimary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 32),

                // Nouveau mot de passe
                TextFormField(
                  controller: _passwordCtrl,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: AppColors.kTextPrimary, fontFamily: 'Plus Jakarta Sans'),
                  decoration: InputDecoration(
                    hintText: 'Nouveau mot de passe',
                    hintStyle: const TextStyle(color: AppColors.kTextTertiary, fontFamily: 'Plus Jakarta Sans'),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.kTextSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.kTextSecondary,
                      ),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                    filled: true,
                    fillColor: AppColors.kBgSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Mot de passe requis';
                    if (v.length < 8) return 'Minimum 8 caractères';
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Confirmation
                TextFormField(
                  controller: _confirmCtrl,
                  obscureText: _obscureConfirm,
                  style: const TextStyle(color: AppColors.kTextPrimary, fontFamily: 'Plus Jakarta Sans'),
                  decoration: InputDecoration(
                    hintText: 'Confirmer le mot de passe',
                    hintStyle: const TextStyle(color: AppColors.kTextTertiary, fontFamily: 'Plus Jakarta Sans'),
                    prefixIcon: const Icon(Icons.lock_outline, color: AppColors.kTextSecondary),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.kTextSecondary,
                      ),
                      onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                    filled: true,
                    fillColor: AppColors.kBgSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Confirmation requise';
                    if (v != _passwordCtrl.text) return 'Les mots de passe ne correspondent pas';
                    return null;
                  },
                ),

                if (provider.error != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.kError.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      provider.error!,
                      style: const TextStyle(
                        color: AppColors.kError,
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  height: AppSpacing.kButtonHeight,
                  child: FilledButton(
                    onPressed: provider.isLoading ? null : _onSubmit,
                    style: FilledButton.styleFrom(shape: const StadiumBorder()),
                    child: provider.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                          )
                        : const Text(
                            'Réinitialiser',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Écran affiché quand le token est expiré ou déjà utilisé.
  Widget _buildInvalidState({required bool isExpired}) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isExpired ? Icons.timer_off_outlined : Icons.link_off_rounded,
              size: 72,
              color: AppColors.kError,
            ),
            const SizedBox(height: 24),
            Text(
              isExpired ? 'Lien expiré' : 'Lien déjà utilisé',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isExpired
                  ? 'Ce lien de réinitialisation n\'est plus valide (15 minutes). Veuillez en demander un nouveau.'
                  : 'Ce lien a déjà été utilisé pour réinitialiser votre mot de passe. Si vous souhaitez le modifier à nouveau, demandez un nouveau lien.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.kTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: AppSpacing.kButtonHeight,
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go(RouteNames.kRouteForgotPassword),
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                child: const Text(
                  'Demander un nouveau lien',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(RouteNames.kRouteLogin),
              child: const Text(
                'Retour à la connexion',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.kTextSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccess() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline_rounded, size: 80, color: AppColors.kSuccess),
            const SizedBox(height: 24),
            const Text(
              'Mot de passe mis à jour !',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColors.kTextPrimary,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Votre mot de passe a été réinitialisé. Vous pouvez maintenant vous connecter.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.kTextSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: AppSpacing.kButtonHeight,
              width: double.infinity,
              child: FilledButton(
                onPressed: () => context.go(RouteNames.kRouteLogin),
                style: FilledButton.styleFrom(shape: const StadiumBorder()),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
