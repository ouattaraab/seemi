import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/tos_provider.dart';

/// Écran d'activation créateur — 5 consentements obligatoires post-KYC.
///
/// Affiché une seule fois après validation KYC, avant que le créateur
/// puisse publier du contenu.
class CreatorConsentsScreen extends StatefulWidget {
  const CreatorConsentsScreen({super.key});

  @override
  State<CreatorConsentsScreen> createState() => _CreatorConsentsScreenState();
}

class _CreatorConsentsScreenState extends State<CreatorConsentsScreen> {
  bool _c1 = false; // Droits sur le contenu
  bool _c2 = false; // Consentement des personnes représentées
  bool _c3 = false; // Interdiction contenu mineur
  bool _c4 = false; // Responsabilité exclusive
  bool _c5 = false; // Coopération judiciaire

  bool get _allAccepted => _c1 && _c2 && _c3 && _c4 && _c5;

  static const _creatorConsentTypes = [
    'creator_content_rights',
    'creator_represented_consent',
    'creator_minor_prohibition',
    'creator_liability',
    'creator_judicial_cooperation',
  ];

  Future<void> _onConfirm() async {
    if (!_allAccepted) return;

    final tosProvider = context.read<TosProvider>();
    final success = await tosProvider.acceptConsentsBatch(_creatorConsentTypes);

    if (!mounted) return;
    if (success) {
      context.go(RouteNames.kRouteHome);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(tosProvider.error ?? 'Erreur lors de l\'enregistrement.'),
          backgroundColor: AppColors.kError,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: AppColors.kBgBase,
        body: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.kScreenMargin, 24, AppSpacing.kScreenMargin, 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.kPrimary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ACTIVATION CRÉATEUR',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                          color: AppColors.kPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Dernière étape',
                      style: AppTextStyles.kHeadlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Votre KYC a été validé ! Acceptez les engagements créateur '
                      'pour commencer à publier du contenu sur SeeMi.',
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: AppColors.kTextSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Consentements ────────────────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.kScreenMargin,
                  ),
                  child: Column(
                    children: [
                      _ConsentCard(
                        number: 1,
                        value: _c1,
                        onChanged: (v) => setState(() => _c1 = v),
                        title: 'Droits sur le contenu publié',
                        text:
                            'Je certifie être l\'auteur ou détenir tous les droits d\'exploitation sur chaque contenu que je publie. '
                            'Je garantis que la publication ne viole aucun droit de tiers. '
                            'En cas de violation, j\'assume seul(e) l\'entière responsabilité civile et pénale.',
                      ),
                      const SizedBox(height: 12),
                      _ConsentCard(
                        number: 2,
                        value: _c2,
                        onChanged: (v) => setState(() => _c2 = v),
                        title: 'Consentement des personnes représentées',
                        text:
                            'Je certifie avoir obtenu le consentement écrit de toute personne identifiable apparaissant dans mon contenu. '
                            'Je confirme que toutes les personnes apparaissant dans mon contenu sont majeures (18 ans ou plus). '
                            'Je m\'engage à conserver ces preuves et à les fournir sur demande.',
                      ),
                      const SizedBox(height: 12),
                      _ConsentCard(
                        number: 3,
                        value: _c3,
                        onChanged: (v) => setState(() => _c3 = v),
                        title: 'Interdiction absolue — contenu impliquant des mineurs',
                        isWarning: true,
                        text:
                            'Je comprends qu\'il m\'est ABSOLUMENT INTERDIT de publier tout contenu impliquant des personnes '
                            'mineures (moins de 18 ans), notamment à caractère sexuel ou suggestif. '
                            'La violation est passible de 2 à 5 ans d\'emprisonnement et 75 000 000 à 100 000 000 FCFA '
                            'd\'amende (Loi n° 2023-593).',
                      ),
                      const SizedBox(height: 12),
                      _ConsentCard(
                        number: 4,
                        value: _c4,
                        onChanged: (v) => setState(() => _c4 = v),
                        title: 'Responsabilité exclusive du créateur',
                        text:
                            'Je reconnais que SeeMi agit en qualité d\'hébergeur technique. '
                            'Je suis seul(e) responsable, pénalement et civilement, du contenu que je publie. '
                            'Je m\'engage à indemniser SeeMi de tout préjudice résultant de mes manquements.',
                      ),
                      const SizedBox(height: 12),
                      _ConsentCard(
                        number: 5,
                        value: _c5,
                        onChanged: (v) => setState(() => _c5 = v),
                        title: 'Consentement à la coopération judiciaire',
                        text:
                            'Je reconnais que SeeMi est légalement tenu de communiquer mes données d\'identification '
                            'aux autorités judiciaires ivoiriennes sur réquisition (art. 72, Loi n° 2013-451). '
                            'Cette communication ne constitue pas une violation de ma vie privée.',
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // ── Bouton confirmer ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.kScreenMargin, 16, AppSpacing.kScreenMargin, 24,
                ),
                child: Consumer<TosProvider>(
                  builder: (context, tosProvider, _) => SizedBox(
                    width: double.infinity,
                    height: AppSpacing.kButtonHeight,
                    child: FilledButton(
                      onPressed:
                          _allAccepted && !tosProvider.isLoading ? _onConfirm : null,
                      style: FilledButton.styleFrom(
                        shape: const StadiumBorder(),
                        elevation: 6,
                        shadowColor:
                            AppColors.kPrimary.withValues(alpha: 0.30),
                        textStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      child: tosProvider.isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Activer mon compte créateur'),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── _ConsentCard ─────────────────────────────────────────────────────────────

class _ConsentCard extends StatelessWidget {
  final int number;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String title;
  final String text;
  final bool isWarning;

  const _ConsentCard({
    required this.number,
    required this.value,
    required this.onChanged,
    required this.title,
    required this.text,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = value
        ? AppColors.kPrimary.withValues(alpha: 0.4)
        : isWarning
            ? AppColors.kError.withValues(alpha: 0.25)
            : AppColors.kBorder;

    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value
              ? AppColors.kPrimary.withValues(alpha: 0.06)
              : AppColors.kBgSurface,
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Checkbox
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: value ? AppColors.kPrimary : Colors.transparent,
                  border: Border.all(
                    color: value
                        ? AppColors.kPrimary
                        : isWarning
                            ? AppColors.kError
                            : AppColors.kBorder,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: value
                    ? const Icon(Icons.check_rounded,
                        size: 13, color: Colors.white)
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: isWarning
                              ? AppColors.kError.withValues(alpha: 0.15)
                              : AppColors.kPrimary.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$number',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: isWarning
                                ? AppColors.kError
                                : AppColors.kPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isWarning
                                ? AppColors.kError
                                : AppColors.kTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    text,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: AppColors.kTextSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
