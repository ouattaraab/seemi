import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';

/// Écran d'acceptation des CGU — affiché après inscription (Level 1).
class TosScreen extends StatelessWidget {
  const TosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        title: const Text('Conditions Générales'),
        backgroundColor: AppColors.kBgBase,
        foregroundColor: AppColors.kTextPrimary,
        elevation: 0,
      ),
      body: Consumer<TosProvider>(
        builder: (context, provider, _) {
          if (provider.tosDeclined) {
            return _buildDeclinedView(context, provider);
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Conditions Générales d'Utilisation",
                        style: AppTextStyles.kHeadlineLarge,
                      ),
                      const SizedBox(height: AppSpacing.kSpaceMd),
                      Text(
                        'Veuillez lire et accepter les conditions générales '
                        "d'utilisation de SeeMi avant de continuer.",
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kTextSecondary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.kSpaceLg),
                      _buildTosContent(),
                    ],
                  ),
                ),
              ),
              if (provider.error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.kScreenMargin,
                  ),
                  child: Text(
                    provider.error!,
                    style: AppTextStyles.kBodyMedium.copyWith(
                      color: AppColors.kError,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (provider.isLoading) ...[
                const SizedBox(height: AppSpacing.kSpaceSm),
                const LinearProgressIndicator(),
              ],
              _buildButtons(context, provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTosContent() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.kSpaceMd),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      child: Text(
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
        style: AppTextStyles.kBodyLarge.copyWith(
          color: AppColors.kTextSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context, TosProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: provider.isLoading
                  ? null
                  : () => _onAccept(context, provider),
              child: const Text("J'accepte les conditions"),
            ),
          ),
          const SizedBox(height: AppSpacing.kSpaceSm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: provider.isLoading
                  ? null
                  : () => provider.declineTos(),
              child: const Text('Refuser'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeclinedView(BuildContext context, TosProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.block,
              size: AppSpacing.kIconSizeHero,
              color: AppColors.kError,
            ),
            const SizedBox(height: AppSpacing.kSpaceLg),
            const Text(
              'Acceptation requise',
              style: AppTextStyles.kHeadlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.kSpaceMd),
            Text(
              "Vous devez accepter les conditions générales d'utilisation "
              'pour continuer à utiliser SeeMi.',
              style: AppTextStyles.kBodyMedium.copyWith(
                color: AppColors.kTextSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.kSpaceXl),
            FilledButton(
              onPressed: () {
                provider.reset();
              },
              child: const Text('Revoir les conditions'),
            ),
            const SizedBox(height: AppSpacing.kSpaceSm),
            OutlinedButton(
              onPressed: () async {
                await const SecureStorageService().clearTokens();
                if (context.mounted) {
                  context.go(RouteNames.kRouteRegister);
                }
              },
              child: const Text("Retour à l'inscription"),
            ),
          ],
        ),
      ),
    );
  }

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
