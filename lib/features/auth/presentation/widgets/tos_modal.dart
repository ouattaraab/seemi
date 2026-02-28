import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';

/// Modale CGU connexion — non-dismissible, affichée à chaque login (Level 2).
///
/// Retourne `true` si accepté, `false` si refusé.
class TosModal extends StatelessWidget {
  final bool isLoading;
  final String? error;

  const TosModal({
    super.key,
    this.isLoading = false,
    this.error,
  });

  /// Affiche la modale CGU. Retourne true si accepté, false si refusé.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppColors.kBgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.kRadiusXl),
        ),
      ),
      builder: (_) => const TosModal(),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.7,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            const Padding(
              padding: EdgeInsets.only(top: AppSpacing.kSpaceSm),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.kBgOverlay,
                  borderRadius: BorderRadius.all(Radius.circular(2)),
                ),
                child: SizedBox(width: 40, height: AppSpacing.kSpaceXs),
              ),
            ),
            // Title
            const Padding(
              padding: EdgeInsets.all(AppSpacing.kScreenMargin),
              child: Text(
                'Rappel des CGU',
                style: AppTextStyles.kHeadlineLarge,
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.kScreenMargin,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'En continuant à utiliser PPV, vous confirmez avoir '
                      "lu et accepté nos conditions générales d'utilisation "
                      'et notre politique de confidentialité.',
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: AppColors.kTextSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.kSpaceLg),
                    _buildSection(
                      'Vos engagements',
                      '• Publier uniquement du contenu dont vous détenez les droits\n'
                          '• Respecter les lois en vigueur\n'
                          '• Ne pas utiliser la plateforme à des fins frauduleuses',
                    ),
                    const SizedBox(height: AppSpacing.kSpaceMd),
                    _buildSection(
                      'Nos engagements',
                      '• Protéger vos données personnelles\n'
                          '• Assurer la sécurité des transactions\n'
                          '• Verser vos gains selon les délais convenus',
                    ),
                    if (error != null) ...[
                      const SizedBox(height: AppSpacing.kSpaceMd),
                      Text(
                        error!,
                        style: AppTextStyles.kBodyMedium.copyWith(
                          color: AppColors.kError,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (isLoading) const LinearProgressIndicator(),
            // Buttons
            Padding(
              padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(true),
                      child: const Text("J'accepte"),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.kSpaceSm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(false),
                      child: const Text('Refuser'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTextStyles.kTitleLarge),
        const SizedBox(height: AppSpacing.kSpaceSm),
        Text(
          content,
          style: AppTextStyles.kBodyMedium.copyWith(
            color: AppColors.kTextSecondary,
            height: 1.6,
          ),
        ),
      ],
    );
  }
}
