import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/content/data/public_content_repository.dart';
import 'package:ppv_app/features/content/presentation/content_detail_provider.dart';
import 'package:ppv_app/features/content/presentation/widgets/hls_video_player.dart';
import 'package:ppv_app/features/payment/presentation/payment_provider.dart';
import 'package:ppv_app/features/payment/presentation/widgets/download_button.dart';
import 'package:ppv_app/features/payment/presentation/widgets/reveal_animation.dart';
import 'package:ppv_app/features/payment/presentation/widgets/tip_bottom_sheet.dart';

/// Écran de détail de contenu — affiché via deep link (/c/:slug).
///
/// Page publique : aucune authentification requise.
/// L'état est géré par [ContentDetailProvider] (contenu) et [PaymentProvider] (paiement).
/// Si [paymentReference] est fourni (callback Paystack), déclenche le reveal automatique.
class ContentDetailScreen extends StatefulWidget {
  final String? paymentReference;

  const ContentDetailScreen({super.key, this.paymentReference});

  @override
  State<ContentDetailScreen> createState() => _ContentDetailScreenState();
}

class _ContentDetailScreenState extends State<ContentDetailScreen>
    with WidgetsBindingObserver {
  bool _dismissedIncentive = false;

  Future<void> _handleBack() async {
    try {
      final hasToken = await SecureStorageService().hasTokens();
      if (!mounted) return;
      if (hasToken) {
        context.go(RouteNames.kRouteHome);
      } else {
        context.go(RouteNames.kRouteOnboarding);
      }
    } catch (_) {
      if (mounted) context.go(RouteNames.kRouteOnboarding);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    if (widget.paymentReference != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _triggerReveal(widget.paymentReference!);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Déclenche automatiquement la vérification de paiement quand l'app
  /// revient au premier plan. Couvre le cas où le navigateur externe
  /// (Paystack) n'a pas redirigé via App Link vers le contenu.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      final paymentProvider = context.read<PaymentProvider>();
      final contentProvider = context.read<ContentDetailProvider>();
      if (paymentProvider.hasPendingPayment &&
          contentProvider.content != null) {
        paymentProvider.checkPaymentAndReveal(
          slug: contentProvider.content!.slug,
          reference: paymentProvider.pendingReference!,
        );
      }
    }
  }

  void _triggerReveal(String reference) {
    final contentProvider = context.read<ContentDetailProvider>();
    final paymentProvider = context.read<PaymentProvider>();

    if (contentProvider.content != null) {
      paymentProvider.checkPaymentAndReveal(
        slug: contentProvider.content!.slug,
        reference: reference,
      );
    } else if (!contentProvider.isLoading) {
      // Contenu non disponible — abandon silencieux
    } else {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) _triggerReveal(reference);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: _buildAppBar(),
      body: Consumer2<ContentDetailProvider, PaymentProvider>(
        builder: (context, contentProvider, paymentProvider, child) =>
            _buildBody(context, contentProvider, paymentProvider),
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.kBgBase,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: AppColors.kTextSecondary),
        onPressed: _handleBack,
        tooltip: 'Fermer',
      ),
      title: const Text.rich(
        TextSpan(
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 20,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.3,
          ),
          children: [
            TextSpan(
              text: 'See',
              style: TextStyle(color: AppColors.kTextPrimary),
            ),
            TextSpan(
              text: 'Mi',
              style: TextStyle(color: AppColors.kAccent),
            ),
          ],
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.kBorder),
      ),
    );
  }

  // ─── Body ─────────────────────────────────────────────────────────────────

  Widget _buildBody(
    BuildContext context,
    ContentDetailProvider contentProvider,
    PaymentProvider paymentProvider,
  ) {
    if (paymentProvider.isCheckingReveal) {
      return const _LoadingState(message: 'Vérification du paiement…');
    }
    if (contentProvider.isLoading) {
      return const _LoadingState(message: 'Chargement du contenu…');
    }
    if (contentProvider.error != null) {
      return _ErrorState(message: contentProvider.error!);
    }

    final content = contentProvider.content!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.kSpaceMd),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // ── Card principale ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.kBgSurface,
                  borderRadius:
                      BorderRadius.circular(AppSpacing.kRadiusXl),
                  border: Border.all(color: AppColors.kBorder),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.kTextPrimary.withValues(alpha: 0.06),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                clipBehavior: Clip.hardEdge,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildImageSection(content, paymentProvider),
                    _buildInfoSection(context, content, paymentProvider),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── Banner inscription post-paiement ─────────────────────
              if (paymentProvider.isPaid && !_dismissedIncentive) ...[
                _SignUpIncentiveBanner(
                  onSignUp: () => context.go(RouteNames.kRouteRegister),
                  onDismiss: () =>
                      setState(() => _dismissedIncentive = true),
                ),
                const SizedBox(height: 16),
              ],

              // ── Footer branding ──────────────────────────────────────
              const Text(
                'Propulsé par SeeMi',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: AppColors.kTextTertiary,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: AppSpacing.kSpace2xl),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Section image ────────────────────────────────────────────────────────

  Widget _buildImageSection(
    PublicContentData content,
    PaymentProvider paymentProvider,
  ) {
    if (paymentProvider.isPaid) {
      // F13 — Résolution en cours : afficher un indicateur de chargement
      if (paymentProvider.isResolvingMedia) {
        return const AspectRatio(
          aspectRatio: 16 / 9,
          child: ColoredBox(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          ),
        );
      }

      // F13 — Média résolu : afficher selon le type
      if (paymentProvider.resolvedMediaUrl != null) {
        if (paymentProvider.mediaType == 'hls') {
          return HlsVideoPlayer(hlsUrl: paymentProvider.resolvedMediaUrl!);
        }
        // Type 'r2' ou non renseigné : comportement existant (image)
        return ColoredBox(
          color: Colors.black,
          child: RevealAnimation(originalUrl: paymentProvider.resolvedMediaUrl!),
        );
      }

      // URL signée disponible mais résolution pas encore lancée : fallback image
      if (paymentProvider.originalUrl != null) {
        return ColoredBox(
          color: Colors.black,
          child: RevealAnimation(originalUrl: paymentProvider.originalUrl!),
        );
      }
    }

    return _BlurredImageWithLock(
      blurPathUrl: content.blurPathUrl,
      priceFcfa: content.priceFcfa,
    );
  }

  // ─── Section infos + actions ──────────────────────────────────────────────

  Widget _buildInfoSection(
    BuildContext context,
    PublicContentData content,
    PaymentProvider paymentProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Badge "débloqué"
          if (paymentProvider.isPaid) ...[
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.kSuccess.withValues(alpha: 0.10),
                borderRadius:
                    BorderRadius.circular(AppSpacing.kRadiusPill),
                border: Border.all(
                    color: AppColors.kSuccess.withValues(alpha: 0.28)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_rounded,
                      color: AppColors.kSuccess, size: 13),
                  SizedBox(width: 5),
                  Text(
                    'CONTENU DÉBLOQUÉ',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.kSuccess,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // ── Créateur + vues ──────────────────────────────────────────
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.kPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    content.creatorName.isNotEmpty
                        ? content.creatorName[0].toUpperCase()
                        : 'C',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: AppColors.kPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  content.creatorName,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              // Compteur de vues
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.kBgElevated,
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_outlined,
                        color: AppColors.kTextTertiary, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${content.viewCount}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.kTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Description + Flash badge ─────────────────────────────────
          if (!paymentProvider.isPaid && content.isFlashActive && content.flashEndsAt != null) ...[
            _FlashCountdown(endsAt: content.flashEndsAt!),
            const SizedBox(height: 8),
          ],
          Text(
            paymentProvider.isPaid
                ? 'Contenu débloqué avec succès !'
                : content.isFlashActive
                    ? 'FLASH : ${content.priceFcfa} FCFA (au lieu de ${content.originalPriceFcfa} FCFA)'
                    : content.isPwyw
                        ? 'Payez ce que vous voulez — minimum ${content.pwywMinimumPriceFcfa} FCFA.'
                        : 'Cette ${content.type == 'video' ? 'vidéo' : 'photo'} est verrouillée. Payez ${content.priceFcfa} FCFA pour la voir.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: paymentProvider.isPaid
                  ? AppColors.kTextPrimary
                  : content.isFlashActive
                      ? const Color(0xFFFF6B00)
                      : AppColors.kTextSecondary,
              height: 1.55,
            ),
          ),

          // ── Social proof badges ──────────────────────────────────────
          if (!paymentProvider.isPaid)
            _buildSocialProofBadge(content.purchaseCount, content.isTrending),

          // ── Téléchargement + Pourboire ────────────────────────────────
          // F13 — Pas de bouton téléchargement pour les vidéos HLS (streaming)
          if (paymentProvider.isPaid &&
              paymentProvider.resolvedMediaUrl != null &&
              paymentProvider.mediaType != 'hls') ...[
            const SizedBox(height: 16),
            DownloadButton(
              downloadUrl: paymentProvider.resolvedMediaUrl!,
              filename:
                  '${content.slug}.${content.type == 'video' ? 'mp4' : 'jpg'}',
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppColors.kBgSurface,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(24))),
                  builder: (_) => TipBottomSheet(
                    slug: content.slug,
                    creatorName: content.creatorName,
                  ),
                ),
                icon: const Icon(Icons.favorite_border_rounded,
                    size: 16, color: AppColors.kSuccess),
                label: const Text(
                  'Laisser un pourboire',
                  style: TextStyle(
                    color: AppColors.kSuccess,
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],

          // ── Erreur paiement ──────────────────────────────────────────
          if (paymentProvider.paymentFailed) ...[
            const SizedBox(height: 16),
            _buildPaymentErrorBanner(
                context, content, paymentProvider),
          ],

          // ── Vérification manuelle (retour du navigateur externe) ─────
          if (paymentProvider.hasPendingPayment) ...[
            const SizedBox(height: 16),
            _buildCheckPaymentBanner(context, content, paymentProvider),
          ],

          // ── Bouton payer ─────────────────────────────────────────────
          if (!paymentProvider.isPaid &&
              !paymentProvider.paymentFailed &&
              !paymentProvider.hasPendingPayment) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.kButtonHeight,
              child: ElevatedButton.icon(
                key: const Key('btn-pay'),
                onPressed: () => _showPaymentDialog(
                  context,
                  content.slug,
                  content.priceFcfa,
                  isPwyw: content.isPwyw,
                  pwywMin: content.pwywMinimumPriceFcfa,
                ),
                icon: const Icon(Icons.lock_open_rounded, size: 20),
                label: Text(
                  content.isFlashActive
                      ? 'Flash · ${content.priceFcfa} FCFA'
                      : content.isPwyw
                          ? 'Payer ce que tu veux'
                          : 'Débloquer · ${content.priceFcfa} FCFA',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: content.isFlashActive
                      ? const Color(0xFFFF6B00)
                      : AppColors.kAccent,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: (content.isFlashActive
                          ? const Color(0xFFFF6B00)
                          : AppColors.kAccent)
                      .withValues(alpha: 0.35),
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Social proof badges ──────────────────────────────────────────────────

  Widget _buildSocialProofBadge(int purchaseCount, bool isTrending) {
    if (purchaseCount <= 0 && !isTrending) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (purchaseCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.kSuccess.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.kSuccess.withValues(alpha: 0.25)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.lock_open_rounded, size: 12, color: AppColors.kSuccess),
                  const SizedBox(width: 4),
                  Text(
                    '$purchaseCount personne${purchaseCount > 1 ? 's ont' : ' a'} débloqué',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.kSuccess,
                    ),
                  ),
                ],
              ),
            ),
          if (isTrending)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B00).withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFF6B00).withValues(alpha: 0.25)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.local_fire_department_rounded, size: 12, color: Color(0xFFFF6B00)),
                  SizedBox(width: 4),
                  Text(
                    'Tendance',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6B00),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── Bannière vérification paiement en attente ────────────────────────────

  Widget _buildCheckPaymentBanner(
    BuildContext context,
    PublicContentData content,
    PaymentProvider paymentProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kPrimary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(
            color: AppColors.kPrimary.withValues(alpha: 0.20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.hourglass_top_rounded,
                  color: AppColors.kPrimary, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Paiement initié. Revenez ici après avoir complété le paiement pour débloquer le contenu.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: AppColors.kPrimary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            key: const Key('btn-check-payment'),
            onPressed: () => paymentProvider.checkPaymentAndReveal(
              slug: content.slug,
              reference: paymentProvider.pendingReference!,
            ),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Vérifier mon paiement'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              key: const Key('btn-new-payment'),
              onPressed: () {
                paymentProvider.reset();
                _showPaymentDialog(context, content.slug, content.priceFcfa);
              },
              child: const Text(
                'Payer à nouveau',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: AppColors.kTextTertiary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bannière erreur paiement ─────────────────────────────────────────────

  Widget _buildPaymentErrorBanner(
    BuildContext context,
    PublicContentData content,
    PaymentProvider paymentProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kError.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(
            color: AppColors.kError.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded,
                  color: AppColors.kError, size: 18),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le paiement n\'a pas abouti. Réessayez ou changez de moyen de paiement.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: AppColors.kError,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('btn-retry-payment'),
            onPressed: () => _showPaymentDialog(
                context, content.slug, content.priceFcfa),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.kError,
              side: BorderSide(
                  color: AppColors.kError.withValues(alpha: 0.38)),
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontWeight: FontWeight.w700,
              ),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  // ─── Dialog paiement ──────────────────────────────────────────────────────

  void _showPaymentDialog(
    BuildContext context,
    String slug,
    int priceFcfa, {
    bool isPwyw = false,
    int pwywMin = 0,
  }) {
    context.read<PaymentProvider>().reset();

    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final pwywController = TextEditingController(
        text: isPwyw ? '$pwywMin' : '');
    final formKey = GlobalKey<FormState>();
    final paymentProvider = context.read<PaymentProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: paymentProvider,
          child: Container(
            decoration: const BoxDecoration(
              color: AppColors.kBgSurface,
              borderRadius: BorderRadius.vertical(
                  top: Radius.circular(AppSpacing.kRadiusXl)),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 12,
              bottom:
                  MediaQuery.of(sheetContext).viewInsets.bottom + 28,
            ),
            child: Consumer<PaymentProvider>(
              builder: (consumerCtx, provider, child) {
                if (provider.hasUrl) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    Navigator.of(sheetContext).pop();
                    launchUrl(
                      Uri.parse(provider.authorizationUrl!),
                      mode: LaunchMode.externalApplication,
                    );
                  });
                }

                return Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Handle
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.kBorder,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Titre
                      Text(
                        isPwyw
                            ? 'Payer ce que vous voulez'
                            : 'Débloquer le contenu',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.kTextPrimary,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Prix badge (non PWYW)
                      if (!isPwyw)
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppColors.kAccent
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.kRadiusPill),
                              border: Border.all(
                                  color: AppColors.kAccent
                                      .withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              '$priceFcfa FCFA',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: AppColors.kAccentDark,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),

                      // Champ PWYW
                      if (isPwyw) ...[
                        Center(
                          child: Text(
                            'Minimum $pwywMin FCFA',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              color: AppColors.kTextSecondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        _SheetPillField(
                          controller: pwywController,
                          hintText: 'Montant que vous souhaitez payer (FCFA)',
                          prefixIcon: Icons.monetization_on_outlined,
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            final val = int.tryParse(v?.trim() ?? '');
                            if (val == null || val < pwywMin) {
                              return 'Montant minimum : $pwywMin FCFA';
                            }
                            return null;
                          },
                        ),
                      ],

                      const SizedBox(height: 24),

                      // Email
                      _SheetPillField(
                        controller: emailController,
                        hintText: 'Adresse email *',
                        prefixIcon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'L\'email est requis';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Téléphone
                      _SheetPillField(
                        controller: phoneController,
                        hintText: 'Téléphone Mobile Money (optionnel)',
                        prefixIcon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                      ),

                      // Erreur
                      if (provider.error != null) ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            const Icon(Icons.error_outline_rounded,
                                color: AppColors.kError, size: 15),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                provider.error!,
                                style: const TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  fontSize: 13,
                                  color: AppColors.kError,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Bouton confirmer
                      SizedBox(
                        height: AppSpacing.kButtonHeight,
                        child: ElevatedButton.icon(
                          key: const Key('btn-confirm-pay'),
                          onPressed: provider.isLoading
                              ? null
                              : () async {
                                  if (!formKey.currentState!.validate()) {
                                    return;
                                  }
                                  int? buyerAmt;
                                  if (isPwyw) {
                                    final val = int.tryParse(
                                        pwywController.text.trim());
                                    if (val != null) {
                                      buyerAmt = val * 100;
                                    }
                                  }
                                  await consumerCtx
                                      .read<PaymentProvider>()
                                      .initiatePayment(
                                        slug: slug,
                                        email: emailController.text
                                            .trim(),
                                        phone: phoneController.text
                                                .trim()
                                                .isEmpty
                                            ? null
                                            : phoneController.text
                                                .trim(),
                                        buyerAmount: buyerAmt,
                                      );
                                },
                          icon: provider.isLoading
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.lock_open_rounded,
                                  size: 20),
                          label: Text(
                            provider.isLoading
                                ? 'Redirection…'
                                : 'Payer avec Paystack',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kAccent,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: AppColors.kAccent
                                .withValues(alpha: 0.35),
                            shape: const StadiumBorder(),
                            textStyle: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    ).whenComplete(() {
      emailController.dispose();
      phoneController.dispose();
      pwywController.dispose();
    });
  }
}

// ─── _LoadingState ────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  final String message;
  const _LoadingState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.kPrimary.withValues(alpha: 0.08),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: AppColors.kPrimary,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              color: AppColors.kTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ErrorState ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.kError.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.lock_outline_rounded,
                  color: AppColors.kError, size: 38),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                color: AppColors.kTextSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _BlurredImageWithLock ────────────────────────────────────────────────────

class _BlurredImageWithLock extends StatelessWidget {
  final String? blurPathUrl;
  final int priceFcfa;

  const _BlurredImageWithLock({
    required this.blurPathUrl,
    required this.priceFcfa,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Image floutée
          if (blurPathUrl != null)
            Image.network(
              blurPathUrl!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  const _ImagePlaceholder(),
            )
          else
            const _ImagePlaceholder(),

          // Overlay gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.18),
                  Colors.black.withValues(alpha: 0.56),
                ],
              ),
            ),
          ),

          // Cadenas + prix
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: AppColors.kAccent,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kAccent.withValues(alpha: 0.45),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusPill),
                  ),
                  child: Text(
                    '$priceFcfa FCFA pour débloquer',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ImagePlaceholder ────────────────────────────────────────────────────────

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.kBgElevated,
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: AppColors.kTextTertiary,
          size: 64,
        ),
      ),
    );
  }
}

// ─── _SheetPillField ──────────────────────────────────────────────────────────

class _SheetPillField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  const _SheetPillField({
    required this.controller,
    required this.hintText,
    required this.prefixIcon,
    this.keyboardType = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
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
        fillColor: AppColors.kBgElevated,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child:
              Icon(prefixIcon, color: AppColors.kTextSecondary, size: 20),
        ),
        prefixIconConstraints:
            const BoxConstraints(minWidth: 48),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(color: AppColors.kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(
              color: AppColors.kPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(
              color: AppColors.kError, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(AppSpacing.kRadiusPill),
          borderSide: const BorderSide(
              color: AppColors.kError, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 20, vertical: 18),
      ),
    );
  }
}

// ─── _SignUpIncentiveBanner ───────────────────────────────────────────────────

class _SignUpIncentiveBanner extends StatelessWidget {
  final VoidCallback onSignUp;
  final VoidCallback onDismiss;

  const _SignUpIncentiveBanner({
    required this.onSignUp,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kAccent.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.kAccent.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: AppColors.kAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retrouvez vos achats',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextPrimary,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Créez un compte gratuit pour accéder à nouveau à ce contenu à tout moment.',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        color: AppColors.kTextSecondary,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ElevatedButton.icon(
            onPressed: onSignUp,
            icon: const Icon(Icons.person_add_rounded, size: 18),
            label: const Text('Créer mon compte'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.kAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: const StadiumBorder(),
              textStyle: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: onDismiss,
              child: const Text(
                'Plus tard',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 12,
                  color: AppColors.kTextTertiary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _FlashCountdown ──────────────────────────────────────────────────────────

class _FlashCountdown extends StatefulWidget {
  final DateTime endsAt;
  const _FlashCountdown({required this.endsAt});
  @override
  State<_FlashCountdown> createState() => _FlashCountdownState();
}

class _FlashCountdownState extends State<_FlashCountdown> {
  late Timer _timer;
  Duration _remaining = Duration.zero;

  @override
  void initState() {
    super.initState();
    _update();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _update());
  }

  void _update() {
    final r = widget.endsAt.difference(DateTime.now());
    if (mounted) {
      setState(() => _remaining = r.isNegative ? Duration.zero : r);
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.inSeconds <= 0) return const SizedBox.shrink();
    final h = _remaining.inHours.toString().padLeft(2, '0');
    final m = (_remaining.inMinutes % 60).toString().padLeft(2, '0');
    final s = (_remaining.inSeconds % 60).toString().padLeft(2, '0');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B00).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: const Color(0xFFFF6B00).withValues(alpha: 0.30)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 13, color: Color(0xFFFF6B00)),
          const SizedBox(width: 4),
          Text(
            'Flash · $h:$m:$s',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF6B00),
            ),
          ),
        ],
      ),
    );
  }
}
