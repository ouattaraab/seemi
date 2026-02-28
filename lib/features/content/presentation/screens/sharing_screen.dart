import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/sharing/data/contact_repository.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';
import 'package:ppv_app/features/sharing/presentation/contact_picker_sheet.dart';

/// Écran de confirmation affichant le lien de partage après publication.
class SharingScreen extends StatelessWidget {
  final String shareUrl;

  const SharingScreen({super.key, required this.shareUrl});

  Future<void> _share(BuildContext context) async {
    final repo = context.read<ShareRepository>();
    await repo.shareContent(shareUrl);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien partagé !')),
    );
  }

  Future<void> _shareToContact(BuildContext context) async {
    final contactRepo = context.read<ContactRepository>();
    final granted = await contactRepo.requestPermission();
    if (!context.mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Permission contacts refusée. Activez-la dans les paramètres.',
          ),
          action: SnackBarAction(
            label: 'Paramètres',
            onPressed: openAppSettings,
          ),
        ),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ContactPickerSheet(
        shareUrl: shareUrl,
        repository: contactRepo,
      ),
    );
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copié !')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        title: Text('Lien de partage', style: AppTextStyles.kHeadlineMedium),
        backgroundColor: AppColors.kBgBase,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.kScreenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: AppSpacing.kSpaceLg),
              Icon(
                Icons.check_circle_outline,
                size: AppSpacing.kIconSizeHero,
                color: AppColors.kSuccess,
              ),
              const SizedBox(height: AppSpacing.kSpaceLg),
              Text(
                'Contenu publié avec succès !',
                style: AppTextStyles.kTitleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.kSpaceMd),
              Text(
                'Partagez ce lien avec vos contacts :',
                style: AppTextStyles.kBodyMedium.copyWith(
                  color: AppColors.kTextSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.kSpaceMd),
              Container(
                padding: const EdgeInsets.all(AppSpacing.kSpaceMd),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.kOutline),
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                ),
                child: SelectableText(
                  shareUrl,
                  style: AppTextStyles.kBodyMedium.copyWith(
                    color: AppColors.kPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.kSpaceLg),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _share(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Partager'),
                ),
              ),
              const SizedBox(height: AppSpacing.kSpaceSm),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: () => _copyLink(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.kPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                    ),
                  ),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copier le lien'),
                ),
              ),
              const SizedBox(height: AppSpacing.kSpaceSm),
              SizedBox(
                height: 48,
                child: FilledButton.tonal(
                  onPressed: () => _shareToContact(context),
                  style: FilledButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.contacts_outlined, size: 18),
                      SizedBox(width: AppSpacing.kSpaceXs),
                      Text('Partager à un contact'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.kSpaceMd),
              SizedBox(
                height: 48,
                child: OutlinedButton(
                  onPressed: () => Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kTextSecondary,
                    side: BorderSide(color: AppColors.kTextSecondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
                    ),
                  ),
                  child: const Text("Retour à l'accueil"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
