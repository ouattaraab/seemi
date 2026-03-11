import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/content/data/public_content_repository.dart';
import 'package:ppv_app/features/content/presentation/content_detail_provider.dart';
import 'package:ppv_app/features/content/presentation/widgets/hls_video_player.dart';
import 'package:ppv_app/features/payment/presentation/payment_provider.dart';
import 'package:ppv_app/features/payment/presentation/widgets/download_button.dart';
import 'package:ppv_app/features/payment/presentation/widgets/reveal_animation.dart';
import 'package:ppv_app/features/payment/presentation/widgets/tip_bottom_sheet.dart';

// ─── Web design tokens ───────────────────────────────────────────────────────
const _kBg       = Color(0xFFF0EDE6); // parchment beige
const _kPaper    = Color(0xFFFAFAF5); // off-white card
const _kInk      = Color(0xFF0A0A0A); // near-black
const _kMuted    = Color(0xFF6B6B6B); // grey body text
const _kBlue     = Color(0xFF4AB5FF); // primary blue
const _kBlueDark = Color(0xFF1240B8); // deep blue
const _kSuccess  = Color(0xFF10B981);
const _kError    = Color(0xFFEF4444);
const _kOrange   = Color(0xFFFF6B00);

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

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !mounted) return;
    final paymentProvider = context.read<PaymentProvider>();
    final contentProvider = context.read<ContentDetailProvider>();
    // Ne déclencher que si on attend un paiement et que le contenu est chargé
    if (paymentProvider.hasPendingPayment &&
        contentProvider.content != null &&
        !paymentProvider.isPaid) {
      paymentProvider.checkPaymentAndReveal(
        slug: contentProvider.content!.slug,
        reference: paymentProvider.pendingReference!,
      );
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
      backgroundColor: _kBg,
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
      backgroundColor: _kPaper,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close_rounded, color: _kInk),
        onPressed: _handleBack,
        tooltip: 'Fermer',
      ),
      title: _LogoPill(),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(height: 2, color: _kInk),
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
      return _ErrorState(
        message: contentProvider.error!,
        isNotFound: contentProvider.isNotFound,
      );
    }

    final content = contentProvider.content!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // ── Card principale ──────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: _kPaper,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kInk, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0xCC0A0A0A),
                      offset: Offset(4, 4),
                      blurRadius: 0,
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

              const SizedBox(height: 20),

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
              Text(
                'Propulsé par SeeMi',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11,
                  color: _kMuted,
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
      if (paymentProvider.isResolvingMedia) {
        return const AspectRatio(
          aspectRatio: 1,
          child: ColoredBox(
            color: _kInk,
            child: Center(
              child: CircularProgressIndicator(color: _kBlue),
            ),
          ),
        );
      }

      if (paymentProvider.resolvedMediaUrl != null) {
        final isVideo = paymentProvider.mediaType == 'hls' ||
            paymentProvider.mediaType == 'video' ||
            (paymentProvider.mediaType == 'r2' && content.type == 'video');
        if (isVideo) {
          return HlsVideoPlayer(hlsUrl: paymentProvider.resolvedMediaUrl!);
        }
        return ColoredBox(
          color: Colors.black,
          child: RevealAnimation(originalUrl: paymentProvider.resolvedMediaUrl!),
        );
      }

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
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: _kSuccess.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: _kSuccess, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: _kSuccess, size: 13),
                  const SizedBox(width: 5),
                  Text(
                    'CONTENU DÉBLOQUÉ',
                    style: GoogleFonts.bebasNeue(
                      color: _kSuccess,
                      fontSize: 13,
                      letterSpacing: 1.2,
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
                  color: _kBlueDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: _kInk, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    content.creatorName.isNotEmpty
                        ? content.creatorName[0].toUpperCase()
                        : 'C',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  content.creatorName,
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _kInk,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _kBg,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: _kInk, width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.visibility_outlined,
                        color: _kMuted, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      '${content.viewCount}',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 11,
                        color: _kMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Flash countdown ───────────────────────────────────────────
          if (!paymentProvider.isPaid && content.isFlashActive && content.flashEndsAt != null) ...[
            _FlashCountdown(endsAt: content.flashEndsAt!),
            const SizedBox(height: 8),
          ],

          // ── Description ───────────────────────────────────────────────
          Text(
            paymentProvider.isPaid
                ? 'Contenu débloqué avec succès !'
                : content.isFlashActive
                    ? 'FLASH : ${content.priceFcfa} FCFA (au lieu de ${content.originalPriceFcfa} FCFA)'
                    : content.isPwyw
                        ? 'Payez ce que vous voulez — minimum ${content.pwywMinimumPriceFcfa} FCFA.'
                        : 'Cette ${content.type == 'video' ? 'vidéo' : 'photo'} est verrouillée. Payez ${content.priceFcfa} FCFA pour la voir.',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 13,
              color: paymentProvider.isPaid
                  ? _kInk
                  : content.isFlashActive
                      ? _kOrange
                      : _kMuted,
              height: 1.55,
            ),
          ),

          // ── Social proof badges ──────────────────────────────────────
          if (!paymentProvider.isPaid)
            _buildSocialProofBadge(content.purchaseCount, content.isTrending),

          // ── Téléchargement + Pourboire ────────────────────────────────
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
                  backgroundColor: _kPaper,
                  shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(16))),
                  builder: (_) => TipBottomSheet(
                    slug: content.slug,
                    creatorName: content.creatorName,
                  ),
                ),
                icon: const Icon(Icons.favorite_border_rounded,
                    size: 16, color: _kSuccess),
                label: Text(
                  'Laisser un pourboire',
                  style: GoogleFonts.ibmPlexMono(
                    color: _kSuccess,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],

          // ── Erreur paiement ──────────────────────────────────────────
          if (paymentProvider.paymentFailed) ...[
            const SizedBox(height: 16),
            _buildPaymentErrorBanner(context, content, paymentProvider),
          ],

          // ── Vérification manuelle ────────────────────────────────────
          if (paymentProvider.hasPendingPayment) ...[
            const SizedBox(height: 16),
            _buildCheckPaymentBanner(context, content, paymentProvider),
          ],

          // ── Bouton payer ─────────────────────────────────────────────
          if (!paymentProvider.isPaid &&
              !paymentProvider.paymentFailed &&
              !paymentProvider.hasPendingPayment) ...[
            const SizedBox(height: 20),
            _PayButton(
              label: content.isFlashActive
                  ? 'Flash · ${content.priceFcfa} FCFA'
                  : content.isPwyw
                      ? 'Payer ce que tu veux'
                      : 'Débloquer · ${content.priceFcfa} FCFA',
              color: content.isFlashActive ? _kOrange : _kBlue,
              onPressed: () => _showPaymentDialog(
                context,
                content.slug,
                content.priceFcfa,
                isPwyw: content.isPwyw,
                pwywMin: content.pwywMinimumPriceFcfa,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Social proof ─────────────────────────────────────────────────────────

  Widget _buildSocialProofBadge(int purchaseCount, bool isTrending) {
    if (purchaseCount <= 0 && !isTrending) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 6,
        children: [
          if (purchaseCount > 0)
            _InkBadge(
              color: _kSuccess,
              icon: Icons.lock_open_rounded,
              label: '$purchaseCount personne${purchaseCount > 1 ? 's ont' : ' a'} débloqué',
            ),
          if (isTrending)
            _InkBadge(
              color: _kOrange,
              icon: Icons.local_fire_department_rounded,
              label: 'Tendance',
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
        color: _kPaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBlueDark, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x401240B8), offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.hourglass_top_rounded, color: _kBlueDark, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Paiement initié. Revenez ici après avoir complété le paiement pour débloquer le contenu.',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    color: _kBlueDark,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PayButton(
            label: 'Vérifier mon paiement',
            color: _kBlueDark,
            onPressed: () => paymentProvider.checkPaymentAndReveal(
              slug: content.slug,
              reference: paymentProvider.pendingReference!,
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
              child: Text(
                'Payer à nouveau',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  color: _kMuted,
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
        color: _kPaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kError, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0x40EF4444), offset: Offset(3, 3), blurRadius: 0),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.error_outline_rounded, color: _kError, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Le paiement n\'a pas abouti. Réessayez ou changez de moyen de paiement.',
                  style: GoogleFonts.ibmPlexMono(
                    fontSize: 12,
                    color: _kError,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _PayButton(
            label: 'Réessayer',
            color: _kError,
            onPressed: () => _showPaymentDialog(
                context, content.slug, content.priceFcfa),
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
    final paymentProvider = context.read<PaymentProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => ChangeNotifierProvider.value(
        value: paymentProvider,
        child: _PaymentSheet(
          slug: slug,
          priceFcfa: priceFcfa,
          isPwyw: isPwyw,
          pwywMin: pwywMin,
        ),
      ),
    );
  }
}

// ─── _PaymentSheet ────────────────────────────────────────────────────────────

class _PaymentSheet extends StatefulWidget {
  final String slug;
  final int priceFcfa;
  final bool isPwyw;
  final int pwywMin;

  const _PaymentSheet({
    required this.slug,
    required this.priceFcfa,
    required this.isPwyw,
    required this.pwywMin,
  });

  @override
  State<_PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<_PaymentSheet> {
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  late final TextEditingController _pwywController;
  final _formKey = GlobalKey<FormState>();

  // Guard contre les double-pops (cause du bug _dependents.isEmpty)
  bool _launched = false;

  // 5 consentements obligatoires
  bool _c1 = false; // CGU + vie privée
  bool _c2 = false; // 18 ans + accès adulte
  bool _c3 = false; // non-remboursable + vue unique
  bool _c4 = false; // droit de visualisation personnel
  bool _c5 = false; // anti-harcèlement / chantage

  bool get _allConsented => _c1 && _c2 && _c3 && _c4 && _c5;

  @override
  void initState() {
    super.initState();
    _pwywController = TextEditingController(
        text: widget.isPwyw ? '${widget.pwywMin}' : '');
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _pwywController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PaymentProvider>(
      builder: (consumerCtx, provider, _) {
        if (provider.hasUrl && !_launched) {
          _launched = true;
          // Planifier une seule fois, vérifier mounted avant de pop
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            final url = provider.authorizationUrl!;
            Navigator.of(context).pop();
            launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
          });
        }

        return Container(
          decoration: const BoxDecoration(
            color: _kPaper,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            border: Border(
              top: BorderSide(color: _kInk, width: 2),
              left: BorderSide(color: _kInk, width: 2),
              right: BorderSide(color: _kInk, width: 2),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
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
                        color: _kInk,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Titre
                  Text(
                    widget.isPwyw
                        ? 'PAYER CE QUE VOUS VOULEZ'
                        : 'DÉBLOQUER LE CONTENU',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 22,
                      color: _kInk,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Prix badge (non PWYW)
                  if (!widget.isPwyw)
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: _kBlue.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: _kBlue, width: 1.5),
                        ),
                        child: Text(
                          '${widget.priceFcfa} FCFA',
                          style: GoogleFonts.bebasNeue(
                            color: _kBlueDark,
                            fontSize: 18,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),

                  // Champ PWYW
                  if (widget.isPwyw) ...[
                    Center(
                      child: Text(
                        'Minimum ${widget.pwywMin} FCFA',
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 12, color: _kMuted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _InkTextField(
                      controller: _pwywController,
                      hintText: 'Montant (FCFA)',
                      prefixIcon: Icons.monetization_on_outlined,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        final val = int.tryParse(v?.trim() ?? '');
                        if (val == null || val < widget.pwywMin) {
                          return 'Montant minimum : ${widget.pwywMin} FCFA';
                        }
                        return null;
                      },
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Email
                  _InkTextField(
                    controller: _emailController,
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
                  const SizedBox(height: 10),

                  // Téléphone
                  _InkTextField(
                    controller: _phoneController,
                    hintText: 'Téléphone Mobile Money (optionnel)',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                  ),

                  const SizedBox(height: 18),

                  // ── Consentements obligatoires ──────────────────────────
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _kInk, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CONSENTEMENTS OBLIGATOIRES',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 13,
                            color: _kInk,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 10),
                        _ConsentRow(
                          value: _c1,
                          onChanged: (v) => setState(() => _c1 = v),
                          text:
                              'J\'accepte les conditions d\'utilisation et la politique de confidentialité de SeeMi.',
                        ),
                        _ConsentRow(
                          value: _c2,
                          onChanged: (v) => setState(() => _c2 = v),
                          text:
                              'J\'atteste avoir 18 ans ou plus et être autorisé(e) à accéder à du contenu pour adultes.',
                        ),
                        _ConsentRow(
                          value: _c3,
                          onChanged: (v) => setState(() => _c3 = v),
                          text:
                              'Je comprends que ce contenu est non-remboursable après déblocage et disponible en vue unique.',
                        ),
                        _ConsentRow(
                          value: _c4,
                          onChanged: (v) => setState(() => _c4 = v),
                          text:
                              'J\'obtiens un droit de visualisation strictement personnel et non transférable. Toute reproduction ou redistribution est interdite (Loi n° 2013-451).',
                        ),
                        _ConsentRow(
                          value: _c5,
                          onChanged: (v) => setState(() => _c5 = v),
                          text:
                              'Je m\'engage à ne jamais utiliser ce contenu à des fins de chantage, harcèlement ou extorsion (Loi n° 2021-893 ; Loi n° 2013-451).',
                          isLast: true,
                        ),
                      ],
                    ),
                  ),

                  // Erreur paiement
                  if (provider.error != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.error_outline_rounded,
                            color: _kError, size: 15),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            provider.error!,
                            style: GoogleFonts.ibmPlexMono(
                                fontSize: 12, color: _kError),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Bouton confirmer
                  _PayButton(
                    label: provider.isLoading
                        ? 'Redirection…'
                        : 'Payer pour débloquer',
                    color: _allConsented ? _kBlue : _kMuted,
                    loading: provider.isLoading,
                    onPressed: (provider.isLoading || !_allConsented)
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) return;
                            int? buyerAmt;
                            if (widget.isPwyw) {
                              final val = int.tryParse(
                                  _pwywController.text.trim());
                              if (val != null) buyerAmt = val * 100;
                            }
                            await consumerCtx
                                .read<PaymentProvider>()
                                .initiatePayment(
                                  slug: widget.slug,
                                  email: _emailController.text.trim(),
                                  phone:
                                      _phoneController.text.trim().isEmpty
                                          ? null
                                          : _phoneController.text.trim(),
                                  buyerAmount: buyerAmt,
                                );
                          },
                  ),

                  if (!_allConsented) ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Text(
                        'Veuillez accepter tous les consentements pour continuer.',
                        style: GoogleFonts.ibmPlexMono(
                            fontSize: 11, color: _kMuted),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── _ConsentRow ──────────────────────────────────────────────────────────────

class _ConsentRow extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String text;
  final bool isLast;

  const _ConsentRow({
    required this.value,
    required this.onChanged,
    required this.text,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () => onChanged(!value),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  margin: const EdgeInsets.only(top: 1),
                  decoration: BoxDecoration(
                    color: value ? _kBlueDark : Colors.transparent,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(
                      color: value ? _kBlueDark : _kInk,
                      width: 1.5,
                    ),
                  ),
                  child: value
                      ? const Icon(Icons.check, color: Colors.white, size: 14)
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    text,
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11,
                      color: _kInk,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          Divider(height: 1, thickness: 1, color: _kInk.withValues(alpha: 0.10)),
      ],
    );
  }
}

// ─── _LogoPill ────────────────────────────────────────────────────────────────

class _LogoPill extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF1240B8), Color(0xFF1A52CC), Color(0xFF1E5FD8)],
        ),
        borderRadius: BorderRadius.circular(100),
        boxShadow: const [
          BoxShadow(
            color: Color(0x4D1240B8),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'SeeMi',
        style: TextStyle(
          fontFamily: 'ADLaM Display',
          color: Colors.white,
          fontSize: 18,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── _PayButton ───────────────────────────────────────────────────────────────

class _PayButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;
  final bool loading;

  const _PayButton({
    required this.label,
    required this.color,
    this.onPressed,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null;
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          color: disabled ? color.withValues(alpha: 0.45) : color,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: _kInk, width: 2),
          boxShadow: disabled
              ? null
              : const [
                  BoxShadow(color: _kInk, offset: Offset(4, 4), blurRadius: 0),
                ],
        ),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            child: Center(
              child: loading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.lock_open_rounded,
                            color: Colors.white, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          label.toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                            color: Colors.white,
                            fontSize: 18,
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _InkBadge ────────────────────────────────────────────────────────────────

class _InkBadge extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;

  const _InkBadge({
    required this.color,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _InkTextField ────────────────────────────────────────────────────────────

class _InkTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData prefixIcon;
  final TextInputType keyboardType;
  final FormFieldValidator<String>? validator;

  const _InkTextField({
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
      style: GoogleFonts.ibmPlexMono(
        fontSize: 14,
        color: _kInk,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: GoogleFonts.ibmPlexMono(fontSize: 13, color: _kMuted),
        filled: true,
        fillColor: _kBg,
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 14, right: 10),
          child: Icon(prefixIcon, color: _kMuted, size: 18),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 44),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kInk, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kInk, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kBlueDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kError, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: _kError, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
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
              color: _kBlue.withValues(alpha: 0.10),
              border: Border.all(color: _kBlueDark, width: 2),
            ),
            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(
                color: _kBlueDark,
                strokeWidth: 2.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: GoogleFonts.ibmPlexMono(fontSize: 13, color: _kMuted),
          ),
        ],
      ),
    );
  }
}

// ─── _ErrorState ──────────────────────────────────────────────────────────────

class _ErrorState extends StatelessWidget {
  final String message;
  final bool isNotFound;
  const _ErrorState({required this.message, this.isNotFound = false});

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
                color: _kError.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _kError, width: 2),
              ),
              child: Icon(
                isNotFound
                    ? Icons.hide_source_rounded
                    : Icons.lock_outline_rounded,
                color: _kError,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 13,
                color: _kMuted,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (isNotFound) ...[
              const SizedBox(height: 24),
              // Retour vers l'accueil web ou l'app si installée
              FilledButton.icon(
                onPressed: () async {
                  final homeUri = Uri.parse('https://seemi.click');
                  if (await canLaunchUrl(homeUri)) {
                    await launchUrl(homeUri,
                        mode: LaunchMode.externalApplication);
                  }
                },
                icon: const Icon(Icons.home_rounded, size: 18),
                label: const Text(
                  'Retour à l\'accueil',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: _kBlueDark,
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
              ),
            ],
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
                  Colors.black.withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.60),
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
                    color: _kBlueDark,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x661240B8),
                        blurRadius: 24,
                        offset: Offset(0, 6),
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
                      horizontal: 16, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kBlueDark,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  child: Text(
                    '$priceFcfa FCFA pour débloquer',
                    style: GoogleFonts.bebasNeue(
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 1.5,
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
      color: const Color(0xFFE5E2DC),
      child: const Center(
        child: Icon(
          Icons.image_outlined,
          color: _kMuted,
          size: 64,
        ),
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
        color: _kPaper,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kInk, width: 2),
        boxShadow: const [
          BoxShadow(color: Color(0xCC0A0A0A), offset: Offset(4, 4), blurRadius: 0),
        ],
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
                  color: _kBlueDark,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kInk, width: 1.5),
                ),
                child: const Icon(
                  Icons.person_add_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Retrouvez vos achats',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 16,
                        color: _kInk,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Créez un compte gratuit pour accéder à nouveau à ce contenu à tout moment.',
                      style: GoogleFonts.ibmPlexMono(
                        fontSize: 12,
                        color: _kMuted,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _PayButton(
            label: 'Créer mon compte',
            color: _kBlueDark,
            onPressed: onSignUp,
          ),
          Center(
            child: TextButton(
              onPressed: onDismiss,
              child: Text(
                'Plus tard',
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 12,
                  color: _kMuted,
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
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _update());
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
        color: _kOrange.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: _kOrange, width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.local_fire_department_rounded,
              size: 13, color: _kOrange),
          const SizedBox(width: 4),
          Text(
            'Flash · $h:$m:$s',
            style: GoogleFonts.ibmPlexMono(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _kOrange,
            ),
          ),
        ],
      ),
    );
  }
}
