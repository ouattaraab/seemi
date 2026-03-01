import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';

/// Écran d'acceptation des CGU — affiché après inscription (Level 1).
class TosScreen extends StatelessWidget {
  const TosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      body: SafeArea(
        child: Consumer<TosProvider>(
          builder: (context, provider, _) {
            if (provider.tosDeclined) {
              return _buildDeclinedView(context, provider);
            }

            return Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                _buildHeader(context),

                // ── Contenu scrollable ─────────────────────────────────────
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Conditions Générales d'Utilisation",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: AppColors.kTextPrimary,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Veuillez lire et accepter les conditions générales '
                              "d'utilisation de SeeMi avant de continuer.",
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 14,
                            color: AppColors.kTextSecondary,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _buildTosContent(),
                      ],
                    ),
                  ),
                ),

                // ── Erreur API ─────────────────────────────────────────────
                if (provider.error != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: _ErrorBanner(message: provider.error!),
                  ),

                // ── Chargement ─────────────────────────────────────────────
                if (provider.isLoading)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.kRadiusPill),
                      child: const LinearProgressIndicator(
                        minHeight: 4,
                        color: AppColors.kPrimary,
                        backgroundColor: AppColors.kBgElevated,
                      ),
                    ),
                  ),

                // ── Boutons ────────────────────────────────────────────────
                _buildButtons(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
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
                size: 18,
                color: AppColors.kTextPrimary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Conditions Générales',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ── Contenu CGU ───────────────────────────────────────────────────────────

  Widget _buildTosContent() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kTextPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'Article 1 – Objet\n\n'
        "Les présentes Conditions Générales d'Utilisation (CGU) régissent "
        "l'accès et l'utilisation de la plateforme SeeMi, "
        'un service permettant aux créateurs de contenu de monétiser '
        'leurs photos et vidéos.\n\n'
        "Article 2 – Conditions d'accès\n\n"
        "L'utilisateur doit être âgé d'au moins 18 ans pour utiliser "
        'la plateforme. Une vérification KYC est requise pour les '
        'créateurs de contenu.\n\n'
        'Article 3 – Responsabilités\n\n'
        "L'utilisateur s'engage à ne publier que du contenu dont il "
        'détient les droits. Tout contenu illicite sera supprimé et '
        'le compte pourra être suspendu.\n\n'
        'Article 4 – Paiements et commissions\n\n'
        'SeeMi prélève une commission sur chaque transaction. Les '
        'reversements sont effectués selon les modalités définies '
        'dans la section dédiée.\n\n'
        'Article 5 – Protection des données\n\n'
        'Les données personnelles sont traitées conformément à notre '
        'politique de confidentialité. Les données KYC sont chiffrées '
        'et stockées de manière sécurisée.',
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 14,
          color: AppColors.kTextSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  // ── Boutons ───────────────────────────────────────────────────────────────

  Widget _buildButtons(BuildContext context, TosProvider provider) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: AppSpacing.kButtonHeight,
            child: FilledButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _onAccept(context, provider),
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: AppColors.kPrimary,
                textStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text("J'accepte les conditions"),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.kButtonHeight,
            child: OutlinedButton(
              onPressed:
                  provider.isLoading ? null : () => provider.declineTos(),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kTextSecondary,
                side: const BorderSide(color: AppColors.kBorder),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text('Refuser'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Vue refus ─────────────────────────────────────────────────────────────

  Widget _buildDeclinedView(BuildContext context, TosProvider provider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône dans double cercle
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.kError.withValues(alpha: 0.08),
            ),
            child: Container(
              margin: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kError.withValues(alpha: 0.14),
              ),
              child: const Icon(
                Icons.block_rounded,
                size: 32,
                color: AppColors.kError,
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Acceptation requise',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.kTextPrimary,
              letterSpacing: -0.3,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          const Text(
            "Vous devez accepter les conditions générales d'utilisation "
            'pour continuer à utiliser SeeMi.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: AppColors.kTextSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.kButtonHeight,
            child: FilledButton(
              onPressed: provider.reset,
              style: FilledButton.styleFrom(
                shape: const StadiumBorder(),
                backgroundColor: AppColors.kPrimary,
                textStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              child: const Text('Revoir les conditions'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: AppSpacing.kButtonHeight,
            child: OutlinedButton(
              onPressed: () async {
                await const SecureStorageService().clearTokens();
                if (context.mounted) {
                  context.go(RouteNames.kRouteRegister);
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.kTextSecondary,
                side: const BorderSide(color: AppColors.kBorder),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: const Text("Retour à l'inscription"),
            ),
          ),
        ],
      ),
    );
  }

  // ── Accept ────────────────────────────────────────────────────────────────

  Future<void> _onAccept(BuildContext context, TosProvider provider) async {
    final success = await provider.acceptTos('registration');
    if (success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('CGU acceptées avec succès.'),
          duration: Duration(seconds: 3),
        ),
      );
      context.go(RouteNames.kRouteKyc);
    }
  }
}

// ── _ErrorBanner ──────────────────────────────────────────────────────────────

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
