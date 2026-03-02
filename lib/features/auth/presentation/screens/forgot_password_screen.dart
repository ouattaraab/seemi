import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/auth/presentation/auth_provider.dart';

/// Écran de demande de réinitialisation de mot de passe.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<AuthProvider>();
    final success = await provider.forgotPassword(email: _emailCtrl.text.trim());

    if (!mounted) return;
    if (success) {
      setState(() => _sent = true);
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
          'Mot de passe oublié',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColors.kTextPrimary,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, provider, child) {
          if (_sent) return _buildSuccess();

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    const Icon(Icons.lock_reset_rounded, size: 64, color: AppColors.kPrimary),
                    const SizedBox(height: 24),
                    const Text(
                      'Réinitialiser votre mot de passe',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Entrez votre adresse email. Nous vous enverrons un lien pour choisir un nouveau mot de passe.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        color: AppColors.kTextSecondary,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Champ email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: AppColors.kTextPrimary, fontFamily: 'Plus Jakarta Sans'),
                      decoration: InputDecoration(
                        hintText: 'Votre adresse email',
                        hintStyle: const TextStyle(color: AppColors.kTextTertiary, fontFamily: 'Plus Jakarta Sans'),
                        prefixIcon: const Icon(Icons.email_outlined, color: AppColors.kTextSecondary),
                        filled: true,
                        fillColor: AppColors.kBgSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Email requis';
                        if (!v.contains('@')) return 'Email invalide';
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
                          style: const TextStyle(color: AppColors.kError, fontFamily: 'Plus Jakarta Sans', fontSize: 13),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      height: AppSpacing.kButtonHeight,
                      child: FilledButton(
                        onPressed: provider.isLoading ? null : _onSend,
                        style: FilledButton.styleFrom(shape: const StadiumBorder()),
                        child: provider.isLoading
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                            : const Text('Envoyer le lien', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700, fontSize: 16)),
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
            const Icon(Icons.mark_email_read_rounded, size: 80, color: AppColors.kSuccess),
            const SizedBox(height: 24),
            const Text(
              'Email envoyé !',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.kTextPrimary),
            ),
            const SizedBox(height: 12),
            Text(
              'Si un compte correspond à ${_emailCtrl.text.trim()}, vous recevrez un lien de réinitialisation sous peu.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans', fontSize: 14, color: AppColors.kTextSecondary, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              height: AppSpacing.kButtonHeight,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.pop(),
                style: OutlinedButton.styleFrom(shape: const StadiumBorder()),
                child: const Text('Retour à la connexion', style: TextStyle(fontFamily: 'Plus Jakarta Sans', fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
