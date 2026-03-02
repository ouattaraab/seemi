import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

/// Écran de réinitialisation de mot de passe, ouvert via deep link.
/// Reçoit [token] et [email] depuis les query params du lien :
/// seemi://reset-password?token=XXX&email=YYY
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

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _passwordCtrl   = TextEditingController();
  final _confirmCtrl    = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm  = true;
  bool _success         = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
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
    if (ok) setState(() => _success = true);
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
      body: Consumer<AuthProvider>(
        builder: (context, provider, _) {
          if (_success) return _buildSuccess();

          return SafeArea(
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
          );
        },
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
