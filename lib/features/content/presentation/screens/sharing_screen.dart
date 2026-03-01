import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/sharing/data/contact_repository.dart';
import 'package:ppv_app/features/sharing/data/share_repository.dart';
import 'package:ppv_app/features/sharing/presentation/contact_picker_sheet.dart';

/// Écran de confirmation affiché après publication — lien + actions de partage.
class SharingScreen extends StatelessWidget {
  final String shareUrl;

  const SharingScreen({super.key, required this.shareUrl});

  // ── Actions ──────────────────────────────────────────────────────────────

  Future<void> _share(BuildContext context) async {
    await context.read<ShareRepository>().shareContent(shareUrl);
  }

  Future<void> _copyLink(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: shareUrl));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Lien copié !')),
    );
  }

  Future<void> _shareToContact(BuildContext context) async {
    final contactRepo = context.read<ContactRepository>();
    final granted = await contactRepo.requestPermission();
    if (!context.mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Permission contacts refusée. Activez-la dans les paramètres.',
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

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    const SizedBox(height: 36),

                    // ── Icône succès ──────────────────────────────────────
                    _buildSuccessIcon(),
                    const SizedBox(height: 24),

                    // ── Titre ─────────────────────────────────────────────
                    const Text(
                      'Contenu publié !',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: AppColors.kTextPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Partagez ce lien pour que vos contacts\npuissent accéder à votre contenu.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: AppColors.kTextSecondary,
                        height: 1.55,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // ── Boîte URL ─────────────────────────────────────────
                    _buildUrlCard(context),
                    const SizedBox(height: 28),

                    // ── Boutons d'action ─────────────────────────────────
                    _buildActions(context),
                    const SizedBox(height: 20),

                    // ── Retour accueil ────────────────────────────────────
                    TextButton(
                      onPressed: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.kTextSecondary,
                        textStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text("Retour à l'accueil"),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, size: 14),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kBgElevated,
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
            'Lien de partage',
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

  // ── Success icon ──────────────────────────────────────────────────────────

  Widget _buildSuccessIcon() {
    return Container(
      width: 92,
      height: 92,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.kSuccess.withValues(alpha: 0.08),
      ),
      child: Container(
        margin: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.kSuccess.withValues(alpha: 0.14),
        ),
        child: const Icon(
          Icons.check_rounded,
          size: 36,
          color: AppColors.kSuccess,
        ),
      ),
    );
  }

  // ── URL card ──────────────────────────────────────────────────────────────

  Widget _buildUrlCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
        boxShadow: [
          BoxShadow(
            color: AppColors.kTextPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.link_rounded,
              size: 18,
              color: AppColors.kPrimary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              shareUrl,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.kPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColors.kBgElevated,
            borderRadius: BorderRadius.circular(9),
            child: InkWell(
              onTap: () => _copyLink(context),
              borderRadius: BorderRadius.circular(9),
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(
                  Icons.copy_rounded,
                  size: 16,
                  color: AppColors.kTextSecondary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Boutons d'action ──────────────────────────────────────────────────────

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        // Partager
        SizedBox(
          width: double.infinity,
          height: AppSpacing.kButtonHeight,
          child: FilledButton.icon(
            onPressed: () => _share(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.share_rounded, size: 18),
            label: const Text('Partager'),
          ),
        ),
        const SizedBox(height: 10),

        // Copier le lien
        SizedBox(
          width: double.infinity,
          height: AppSpacing.kButtonHeight,
          child: OutlinedButton.icon(
            onPressed: () => _copyLink(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kPrimary,
              side: BorderSide(
                  color: AppColors.kPrimary.withValues(alpha: 0.38)),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.copy_rounded, size: 18),
            label: const Text('Copier le lien'),
          ),
        ),
        const SizedBox(height: 10),

        // Envoyer à un contact
        SizedBox(
          width: double.infinity,
          height: AppSpacing.kButtonHeight,
          child: OutlinedButton.icon(
            onPressed: () => _shareToContact(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kTextSecondary,
              side: const BorderSide(color: AppColors.kBorder),
              backgroundColor: AppColors.kBgSurface,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            icon: const Icon(Icons.contacts_outlined, size: 18),
            label: const Text('Envoyer à un contact'),
          ),
        ),
      ],
    );
  }
}
