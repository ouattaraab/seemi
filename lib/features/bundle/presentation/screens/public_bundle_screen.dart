import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/bundle/data/bundle(_repository ?? context.read<BundleRepository>()).dart';
import 'package:ppv_app/features/bundle/domain/bundle.dart';
import 'package:provider/provider.dart';

/// Écran public d'un bundle — accessible via deep link `/b/{slug}`.
///
/// Si [paymentReference] est fourni (callback Paystack), vérifie automatiquement
/// le paiement et affiche les contenus débloqués.
class PublicBundleScreen extends StatefulWidget {
  final String slug;
  final String? paymentReference;

  const PublicBundleScreen({
    super.key,
    required this.slug,
    this.paymentReference,
  });

  @override
  State<PublicBundleScreen> createState() => _PublicBundleScreenState();
}

class _PublicBundleScreenState extends State<PublicBundleScreen> {
  BundleRepository? _repository;

  Bundle? _bundle;
  bool _isLoading = true;
  bool _isVerifying = false;
  String? _error;
  String? _confirmedReference;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _repository = context.read<BundleRepository>();
      _loadBundle();
    });
  }

  Future<void> _loadBundle() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      // Charge le bundle avec la référence si disponible (pour obtenir isPaid)
      final bundle = await (_repository ?? context.read<BundleRepository>()).getPublicBundle(
        widget.slug,
        ref: widget.paymentReference,
      );

      if (mounted) {
        setState(() {
          _bundle = bundle;
          _isLoading = false;
          if (bundle.isPaid && widget.paymentReference != null) {
            _confirmedReference = widget.paymentReference;
          }
        });
      }

      // Si la référence est fournie mais le paiement n'est pas encore confirmé,
      // tenter la vérification (cas webhook Paystack retardé)
      if (!bundle.isPaid && widget.paymentReference != null) {
        await _verifyAndReload(widget.paymentReference!);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Impossible de charger ce bundle. Vérifiez votre connexion.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _verifyAndReload(String reference) async {
    if (!mounted) return;
    setState(() => _isVerifying = true);
    try {
      final success = await (_repository ?? context.read<BundleRepository>()).verifyPayment(reference);
      if (!mounted) return;
      if (success) {
        // Recharge avec la référence confirmée pour obtenir isPaid = true
        final updated = await (_repository ?? context.read<BundleRepository>()).getPublicBundle(
          widget.slug,
          ref: reference,
        );
        if (mounted) {
          setState(() {
            _bundle = updated;
            _confirmedReference = reference;
            _isVerifying = false;
          });
        }
      } else {
        if (mounted) setState(() => _isVerifying = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.kBgBase,
        body: Center(child: CircularProgressIndicator(color: AppColors.kPrimary)),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: AppColors.kBgBase,
        body: _ErrorView(message: _error!, onRetry: _loadBundle),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      body: _BundleContent(
        bundle: _bundle!,
        repository: _repository,
        bundleReference: _confirmedReference,
        isVerifying: _isVerifying,
        onVerifyAndReload: _verifyAndReload,
      ),
    );
  }
}

// ─── _BundleContent ───────────────────────────────────────────────────────────

class _BundleContent extends StatelessWidget {
  final Bundle bundle;
  final BundleRepository repository;
  final String? bundleReference;
  final bool isVerifying;
  final Future<void> Function(String ref) onVerifyAndReload;

  const _BundleContent({
    required this.bundle,
    required this.repository,
    required this.bundleReference,
    required this.isVerifying,
    required this.onVerifyAndReload,
  });

  @override
  Widget build(BuildContext context) {
    final isPaid = bundle.isPaid;
    final hasDiscount = bundle.discountPercent > 0;
    final avatarInitial = (bundle.creatorName?.isNotEmpty == true)
        ? bundle.creatorName![0].toUpperCase()
        : '?';

    return CustomScrollView(
      slivers: [
        // ── AppBar ─────────────────────────────────────────────────────
        SliverAppBar(
          backgroundColor: AppColors.kBgBase,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          pinned: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: AppColors.kTextPrimary, size: 20),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
          title: Text(
            bundle.title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.kTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          centerTitle: false,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Divider(
                height: 1, color: AppColors.kBorder.withValues(alpha: 0.6)),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Badge débloqué ────────────────────────────────────
                if (isPaid) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.kSuccess.withValues(alpha: 0.10),
                      borderRadius:
                          BorderRadius.circular(AppSpacing.kRadiusMd),
                      border: Border.all(
                          color: AppColors.kSuccess.withValues(alpha: 0.30)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: AppColors.kSuccess, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Bundle débloqué — Appuyez sur un contenu pour le voir',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.kSuccess,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Vérification en cours ─────────────────────────────
                if (isVerifying) ...[
                  const Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.kPrimary),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Vérification du paiement…',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: AppColors.kTextSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Créateur ─────────────────────────────────────────
                if (bundle.creatorName != null) ...[
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.kPrimary.withValues(alpha: 0.12),
                          border: Border.all(color: AppColors.kBorder),
                        ),
                        child: bundle.creatorAvatarUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  bundle.creatorAvatarUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(
                                      avatarInitial,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.kPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                              )
                            : Center(
                                child: Text(
                                  avatarInitial,
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.kPrimary,
                                  ),
                                ),
                              ),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bundle.creatorName!,
                            style: AppTextStyles.kBodyMedium
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          if (bundle.creatorUsername != null)
                            Text(
                              '@${bundle.creatorUsername}',
                              style: AppTextStyles.kCaption,
                            ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Titre + description ───────────────────────────────
                Text(bundle.title, style: AppTextStyles.kHeadlineMedium),
                if (bundle.description != null &&
                    bundle.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    bundle.description!,
                    style: AppTextStyles.kBodyMedium
                        .copyWith(color: AppColors.kTextSecondary, height: 1.5),
                  ),
                ],
                const SizedBox(height: 20),

                // ── Miniatures des contenus ───────────────────────────
                if (bundle.items.isNotEmpty) ...[
                  Text(
                    '${bundle.itemsCount} contenu${bundle.itemsCount > 1 ? 's' : ''} inclus',
                    style: AppTextStyles.kBodyMedium
                        .copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 130,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: bundle.items.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (ctx, i) => _ItemPreviewCard(
                        item: bundle.items[i],
                        isPaid: isPaid,
                        bundleReference: bundleReference,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // ── Prix ─────────────────────────────────────────────
                if (!isPaid) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.kBgSurface,
                      borderRadius:
                          BorderRadius.circular(AppSpacing.kRadiusMd),
                      border: Border.all(color: AppColors.kBorder),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Prix du bundle',
                                style: AppTextStyles.kCaption,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  if (hasDiscount) ...[
                                    Text(
                                      '${_fmt(bundle.totalPriceFcfa)} FCFA',
                                      style: AppTextStyles.kBodyMedium.copyWith(
                                        decoration: TextDecoration.lineThrough,
                                        color: AppColors.kTextTertiary,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Text(
                                    '${_fmt(bundle.discountedPriceFcfa)} FCFA',
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.kSuccess,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        if (hasDiscount)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.kSuccess.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.kRadiusPill),
                            ),
                            child: Text(
                              '-${bundle.discountPercent}%',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.kSuccess,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── CTA ─────────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: AppSpacing.kButtonHeight,
                    child: FilledButton.icon(
                      onPressed: () => _openPaymentSheet(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.kPrimary,
                        shape: const StadiumBorder(),
                        textStyle: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      icon: const Icon(Icons.lock_open_rounded, size: 20),
                      label: Text(
                        'Débloquer le bundle — ${_fmt(bundle.discountedPriceFcfa)} FCFA',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _openPaymentSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.kBgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      builder: (_) => _BundlePaymentSheet(
        bundle: bundle,
        repository: repository,
        onPaymentConfirmed: (ref) {
          Navigator.of(context).pop();
          onVerifyAndReload(ref);
        },
      ),
    );
  }

  static String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── _ItemPreviewCard ─────────────────────────────────────────────────────────

class _ItemPreviewCard extends StatelessWidget {
  final BundleItem item;
  final bool isPaid;
  final String? bundleReference;

  const _ItemPreviewCard({
    required this.item,
    required this.isPaid,
    required this.bundleReference,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isPaid && item.slug.isNotEmpty
          ? () {
              final path = '/c/${item.slug}';
              final ref = bundleReference;
              context.push(ref != null ? '$path?reference=$ref' : path);
            }
          : null,
      child: SizedBox(
        width: 110,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail
              item.blurUrl.isNotEmpty
                  ? Image.network(
                      item.blurUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.kBgElevated,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.kTextTertiary),
                      ),
                    )
                  : Container(
                      color: AppColors.kBgElevated,
                      child: const Icon(Icons.image_outlined,
                          color: AppColors.kTextTertiary),
                    ),
              // Gradient
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.65),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              // Lock / unlock icon
              Center(
                child: Icon(
                  isPaid
                      ? Icons.play_circle_fill_rounded
                      : Icons.lock_rounded,
                  color: isPaid ? Colors.white : Colors.white70,
                  size: 28,
                ),
              ),
              // Type badge
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    item.type == 'video'
                        ? Icons.videocam_rounded
                        : Icons.image_rounded,
                    size: 11,
                    color: Colors.white,
                  ),
                ),
              ),
              // Price / unlocked label
              Positioned(
                bottom: 6,
                left: 6,
                right: 6,
                child: Text(
                  isPaid ? 'Voir' : '${_fmt(item.priceFcfa)} F',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: isPaid ? AppColors.kSuccess : Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── _BundlePaymentSheet ──────────────────────────────────────────────────────

class _BundlePaymentSheet extends StatefulWidget {
  final Bundle bundle;
  final BundleRepository repository;
  final void Function(String reference) onPaymentConfirmed;

  const _BundlePaymentSheet({
    required this.bundle,
    required this.repository,
    required this.onPaymentConfirmed,
  });

  @override
  State<_BundlePaymentSheet> createState() => _BundlePaymentSheetState();
}

class _BundlePaymentSheetState extends State<_BundlePaymentSheet> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _isVerifying = false;
  String? _error;
  String? _pendingReference;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initiatePayment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await widget.repository.initiatePayment(
        bundleSlug: widget.bundle.slug,
        email: _emailController.text.trim(),
      );

      final authUrl = result['authorizationUrl']!;
      final reference = result['reference']!;

      if (!mounted) return;

      _pendingReference = reference;
      setState(() => _isLoading = false);

      final uri = Uri.parse(authUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        if (mounted) setState(() {});
      } else {
        if (mounted) {
          setState(() {
            _error = 'Impossible d\'ouvrir le lien de paiement.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erreur lors de l\'initiation du paiement. Réessayez.';
        });
      }
    }
  }

  Future<void> _verifyPayment() async {
    if (_pendingReference == null) return;

    setState(() {
      _isVerifying = true;
      _error = null;
    });

    try {
      final success = await widget.repository.verifyPayment(_pendingReference!);
      if (!mounted) return;

      if (success) {
        widget.onPaymentConfirmed(_pendingReference!);
      } else {
        setState(() {
          _error = 'Paiement non encore confirmé. Réessayez dans quelques instants.';
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isVerifying = false;
          _error = 'Impossible de vérifier le paiement. Réessayez.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Titre
          Text('Débloquer le bundle', style: AppTextStyles.kTitleLarge),
          const SizedBox(height: 4),
          Text(
            'Entrez votre email pour recevoir vos contenus.',
            style: AppTextStyles.kBodyMedium
                .copyWith(color: AppColors.kTextSecondary),
          ),
          const SizedBox(height: 20),

          if (_pendingReference != null) ...[
            // Vérification en attente
            Text(
              'Le paiement a été initié. Revenez après avoir payé pour confirmer.',
              style: AppTextStyles.kBodyMedium
                  .copyWith(color: AppColors.kTextSecondary, height: 1.5),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.kButtonHeight,
              child: FilledButton.icon(
                onPressed: _isVerifying ? null : _verifyPayment,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  shape: const StadiumBorder(),
                ),
                icon: _isVerifying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.verified_rounded, size: 20),
                label: Text(
                  _isVerifying ? 'Vérification…' : 'Confirmer mon paiement',
                  style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ] else ...[
            // Formulaire email
            Form(
              key: _formKey,
              child: TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: AppColors.kTextPrimary,
                ),
                decoration: InputDecoration(
                  hintText: 'votre@email.com',
                  hintStyle: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    color: AppColors.kTextTertiary,
                  ),
                  filled: true,
                  fillColor: AppColors.kBgElevated,
                  prefixIcon: const Icon(Icons.email_outlined,
                      color: AppColors.kTextSecondary, size: 20),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.kBorder),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusMd),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: AppColors.kPrimary, width: 1.5),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusMd),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.kError),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusMd),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderSide: const BorderSide(
                        color: AppColors.kError, width: 1.5),
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusMd),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email requis';
                  if (!v.contains('@')) return 'Email invalide';
                  return null;
                },
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              _ErrorBanner(message: _error!),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: AppSpacing.kButtonHeight,
              child: FilledButton(
                onPressed: _isLoading ? null : _initiatePayment,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.kPrimary,
                  shape: const StadiumBorder(),
                  textStyle: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Text('Payer via Paystack'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── _ErrorBanner ─────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.kError.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusMd),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.kError, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.kCaption.copyWith(color: AppColors.kError),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── _ErrorView ───────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.kTextTertiary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.kBodyMedium
                  .copyWith(color: AppColors.kTextSecondary),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
              ),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
