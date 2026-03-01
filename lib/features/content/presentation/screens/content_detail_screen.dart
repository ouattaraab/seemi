import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/features/content/data/public_content_repository.dart';
import 'package:ppv_app/features/content/presentation/content_detail_provider.dart';
import 'package:ppv_app/features/payment/presentation/payment_provider.dart';
import 'package:ppv_app/features/payment/presentation/widgets/download_button.dart';
import 'package:ppv_app/features/payment/presentation/widgets/reveal_animation.dart';

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

class _ContentDetailScreenState extends State<ContentDetailScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.paymentReference != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final contentProvider = context.read<ContentDetailProvider>();
        final paymentProvider = context.read<PaymentProvider>();

        void triggerReveal() {
          if (contentProvider.content != null) {
            paymentProvider.checkPaymentAndReveal(
              slug: contentProvider.content!.slug,
              reference: widget.paymentReference!,
            );
          } else if (!contentProvider.isLoading) {
            // Contenu non disponible — abandon silencieux
          } else {
            Future.delayed(const Duration(milliseconds: 500), () {
              if (mounted) triggerReveal();
            });
          }
        }

        triggerReveal();
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
      automaticallyImplyLeading: false,
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
    if (paymentProvider.isPaid && paymentProvider.originalUrl != null) {
      return AspectRatio(
        aspectRatio: 1,
        child: RevealAnimation(originalUrl: paymentProvider.originalUrl!),
      );
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

          // ── Description ──────────────────────────────────────────────
          Text(
            paymentProvider.isPaid
                ? 'Contenu débloqué avec succès !'
                : 'Cette ${content.type == 'video' ? 'vidéo' : 'photo'} est verrouillée. Payez ${content.priceFcfa} FCFA pour la voir.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: paymentProvider.isPaid
                  ? AppColors.kTextPrimary
                  : AppColors.kTextSecondary,
              height: 1.55,
            ),
          ),

          // ── Téléchargement ───────────────────────────────────────────
          if (paymentProvider.isPaid &&
              paymentProvider.originalUrl != null) ...[
            const SizedBox(height: 16),
            DownloadButton(
              downloadUrl: paymentProvider.originalUrl!,
              filename:
                  '${content.slug}.${content.type == 'video' ? 'mp4' : 'jpg'}',
            ),
          ],

          // ── Erreur paiement ──────────────────────────────────────────
          if (paymentProvider.paymentFailed) ...[
            const SizedBox(height: 16),
            _buildPaymentErrorBanner(
                context, content, paymentProvider),
          ],

          // ── Bouton payer ─────────────────────────────────────────────
          if (!paymentProvider.isPaid &&
              !paymentProvider.paymentFailed) ...[
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
                ),
                icon: const Icon(Icons.lock_open_rounded, size: 20),
                label: Text('Débloquer · ${content.priceFcfa} FCFA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.kAccent,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor:
                      AppColors.kAccent.withValues(alpha: 0.35),
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
      BuildContext context, String slug, int priceFcfa) {
    context.read<PaymentProvider>().reset();

    final emailController = TextEditingController();
    final phoneController = TextEditingController();
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
                      const Text(
                        'Débloquer le contenu',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.kTextPrimary,
                          letterSpacing: -0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),

                      // Prix badge
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color:
                                AppColors.kAccent.withValues(alpha: 0.10),
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
