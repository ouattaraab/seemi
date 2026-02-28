import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
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
    // Si un paymentReference est présent (callback Paystack), lancer le reveal
    if (widget.paymentReference != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final contentProvider = context.read<ContentDetailProvider>();
        final paymentProvider = context.read<PaymentProvider>();

        // Attendre que le contenu soit chargé pour récupérer le slug
        void triggerReveal() {
          if (contentProvider.content != null) {
            paymentProvider.checkPaymentAndReveal(
              slug: contentProvider.content!.slug,
              reference: widget.paymentReference!,
            );
          } else if (!contentProvider.isLoading) {
            // Contenu non disponible — abandon silencieux
          } else {
            // Contenu encore en chargement — réessayer après 500ms
            // Guard mounted : évite d'accéder au context après dispose()
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
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        elevation: 0,
        title: const Text(
          'PPV – Paye Pour Voir',
          style: TextStyle(
            color: AppColors.kPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer2<ContentDetailProvider, PaymentProvider>(
        builder: (context, contentProvider, paymentProvider, _) =>
            _buildBody(context, contentProvider, paymentProvider),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    ContentDetailProvider contentProvider,
    PaymentProvider paymentProvider,
  ) {
    // Spinner de vérification paiement (polling en cours)
    if (paymentProvider.isCheckingReveal) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: AppColors.kPrimary),
            SizedBox(height: 16),
            Text(
              'Vérification du paiement...',
              style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
            ),
          ],
        ),
      );
    }

    if (contentProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.kPrimary),
      );
    }

    if (contentProvider.error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, color: Colors.white54, size: 64),
              const SizedBox(height: 16),
              Text(
                contentProvider.error!,
                style: const TextStyle(color: Colors.white70, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    final content = contentProvider.content!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.kBgSurface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black54,
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            clipBehavior: Clip.hardEdge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Afficher l'animation reveal ou l'image floutée avec cadenas
                if (paymentProvider.isPaid && paymentProvider.originalUrl != null)
                  AspectRatio(
                    aspectRatio: 1,
                    child: RevealAnimation(
                      originalUrl: paymentProvider.originalUrl!,
                    ),
                  )
                else
                  _BlurredImageWithLock(blurPathUrl: content.blurPathUrl),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge "Contenu débloqué" affiché après reveal
                      if (paymentProvider.isPaid) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.kPrimary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            '✓ Contenu débloqué',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      Text(
                        'Par ${content.creatorName}',
                        style: const TextStyle(
                          color: Color(0xFFAAAAAA),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        paymentProvider.isPaid
                            ? 'Contenu débloqué !'
                            : 'Cette photo est verrouillée. Payez ${content.priceFcfa} FCFA pour la voir.',
                        style: const TextStyle(
                          color: Color(0xFFF0F0F0),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility_outlined,
                            color: Color(0xFF888888),
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${content.viewCount} personne${content.viewCount > 1 ? 's ont' : ' a'} vu ce contenu',
                            style: const TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      // Bouton de téléchargement — visible après paiement (Story 5.4)
                      if (paymentProvider.isPaid &&
                          paymentProvider.originalUrl != null) ...[
                        const SizedBox(height: 16),
                        DownloadButton(
                          downloadUrl: paymentProvider.originalUrl!,
                          filename:
                              '${content.slug}.${content.type == 'video' ? 'mp4' : 'jpg'}',
                        ),
                      ],
                      // Bandeau d'erreur paiement (Story 5.5)
                      if (paymentProvider.paymentFailed) ...[
                        const SizedBox(height: 16),
                        _buildPaymentErrorBanner(context, content, paymentProvider),
                      ],
                      // Bouton paiement masqué si déjà payé ou si paiement échoué
                      if (!paymentProvider.isPaid && !paymentProvider.paymentFailed) ...[
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            key: const Key('btn-pay'),
                            onPressed: () => _showPaymentDialog(
                              context,
                              content.slug,
                              content.priceFcfa,
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.kAccentOrange,
                              foregroundColor: Colors.black,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              textStyle: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            child: Text('Payer ${content.priceFcfa} FCFA'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentErrorBanner(
    BuildContext context,
    PublicContentData content,
    PaymentProvider paymentProvider,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2C1A1A),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6B6B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Le paiement n\'a pas abouti. Réessayez ou changez de moyen de paiement.',
            style: TextStyle(
              color: Color(0xFFFF6B6B),
              fontSize: 14,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            key: const Key('btn-retry-payment'),
            onPressed: () => _showPaymentDialog(context, content.slug, content.priceFcfa),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFFFF6B6B),
              side: const BorderSide(color: Color(0xFFFF6B6B)),
            ),
            child: const Text('Réessayer'),
          ),
        ],
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, String slug, int priceFcfa) {
    // Remet le provider à zéro avant d'ouvrir le dialog
    context.read<PaymentProvider>().reset();

    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    // H1 fix : capture le provider AVANT le push du BottomSheet afin qu'il soit
    // accessible via ChangeNotifierProvider.value dans la route Overlay (qui est
    // au-dessus du MultiProvider dans la hiérarchie GoRouter).
    final paymentProvider = context.read<PaymentProvider>();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return ChangeNotifierProvider.value(
          value: paymentProvider,
          child: Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 24,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Consumer<PaymentProvider>(
              builder: (consumerCtx, provider, __) {
                // Redirection automatique dès que l'URL est disponible
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
                      Text(
                        'Payer $priceFcfa FCFA',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Email *',
                          labelStyle: TextStyle(color: Color(0xFFAAAAAA)),
                          filled: true,
                          fillColor: Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF00BFA5)),
                          ),
                        ),
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
                      TextFormField(
                        controller: phoneController,
                        keyboardType: TextInputType.phone,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          labelText: 'Téléphone Mobile Money (optionnel)',
                          hintText: '+225 07 XX XX XX XX',
                          hintStyle: TextStyle(color: Color(0xFF666666)),
                          labelStyle: TextStyle(color: Color(0xFFAAAAAA)),
                          filled: true,
                          fillColor: Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF00BFA5)),
                          ),
                        ),
                      ),
                      if (provider.error != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          provider.error!,
                          style: const TextStyle(
                            color: Color(0xFFFF6B6B),
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      ElevatedButton(
                        key: const Key('btn-confirm-pay'),
                        onPressed: provider.isLoading
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                await consumerCtx
                                    .read<PaymentProvider>()
                                    .initiatePayment(
                                      slug: slug,
                                      email: emailController.text.trim(),
                                      phone: phoneController.text.trim().isEmpty
                                          ? null
                                          : phoneController.text.trim(),
                                    );
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kAccentOrange,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.black,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text('Confirmer et payer $priceFcfa FCFA'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    // M2 fix : dispose des controllers après fermeture du BottomSheet.
    ).whenComplete(() {
      emailController.dispose();
      phoneController.dispose();
    });
  }
}

class _BlurredImageWithLock extends StatelessWidget {
  final String? blurPathUrl;

  const _BlurredImageWithLock({required this.blurPathUrl});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (blurPathUrl != null)
            Image.network(
              blurPathUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const _ImagePlaceholder(),
            )
          else
            const _ImagePlaceholder(),
          // Overlay cadenas
          Container(
            color: Colors.black38,
            child: const Center(
              child: Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF111111),
      child: const Center(
        child: Icon(Icons.image_outlined, color: Color(0xFF444444), size: 80),
      ),
    );
  }
}
