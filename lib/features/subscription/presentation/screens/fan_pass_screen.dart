import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/subscription/data/subscription_repository.dart';
import 'package:provider/provider.dart';

class FanPassScreen extends StatefulWidget {
  final int creatorId;
  final String creatorName;

  const FanPassScreen({
    super.key,
    required this.creatorId,
    required this.creatorName,
  });

  @override
  State<FanPassScreen> createState() => _FanPassScreenState();
}

class _FanPassScreenState extends State<FanPassScreen> {
  List<SubscriptionTier> _tiers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _tiers = await context.read<SubscriptionRepository>().getTiersByCreator(widget.creatorId);
    } catch (_) {
      _error = 'Impossible de charger les Fan Pass.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _subscribe(SubscriptionTier tier) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.kBgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SubscribeSheet(tier: tier, repository: _repo),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.kBgBase,
      appBar: AppBar(
        backgroundColor: AppColors.kBgBase,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.kTextPrimary,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Fan Pass · ${widget.creatorName}',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.kTextPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: AppColors.kBorder.withValues(alpha: 0.6),
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.kPrimary),
            )
          : _error != null
              ? Center(
                  child: Text(
                    _error!,
                    style: AppTextStyles.kBodyMedium
                        .copyWith(color: AppColors.kTextSecondary),
                  ),
                )
              : _tiers.isEmpty
                  ? Center(
                      child: Text(
                        'Ce créateur n\'a pas encore de Fan Pass.',
                        style: AppTextStyles.kBodyMedium
                            .copyWith(color: AppColors.kTextSecondary),
                        textAlign: TextAlign.center,
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(20),
                      itemCount: _tiers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final tier = _tiers[i];
                        return Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.kBgSurface,
                            borderRadius:
                                BorderRadius.circular(AppSpacing.kRadiusXl),
                            border: Border.all(color: AppColors.kBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    tier.name,
                                    style: const TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.kTextPrimary,
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.kPrimary,
                                      borderRadius: BorderRadius.circular(
                                          AppSpacing.kRadiusPill),
                                    ),
                                    child: Text(
                                      '${_fmt(tier.priceMonthlyFcfa)} F/mois',
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (tier.description != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  tier.description!,
                                  style: AppTextStyles.kBodyMedium.copyWith(
                                    color: AppColors.kTextSecondary,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Text(
                                '${tier.activeSubscribers} abonné(s)',
                                style: AppTextStyles.kCaption.copyWith(
                                  color: AppColors.kTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: AppSpacing.kButtonHeight,
                                child: FilledButton(
                                  onPressed: () => _subscribe(tier),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.kPrimary,
                                    shape: const StadiumBorder(),
                                  ),
                                  child: const Text(
                                    'S\'abonner',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}

// ── Phase du sheet ────────────────────────────────────────────────────────────
enum _SubscribePhase { form, pending, verifying, success, error }

class _SubscribeSheet extends StatefulWidget {
  final SubscriptionTier tier;
  final SubscriptionRepository repository;

  const _SubscribeSheet({required this.tier, required this.repository});

  @override
  State<_SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends State<_SubscribeSheet> {
  final _emailController = TextEditingController();
  _SubscribePhase _phase = _SubscribePhase.form;
  String? _error;

  // Conservés après l'initiation pour la vérification
  String? _pendingReference;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _initiate() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Email invalide');
      return;
    }
    setState(() {
      _phase = _SubscribePhase.verifying; // spinner pendant l'appel API
      _error = null;
    });
    try {
      final result = await widget.repository.initiateSubscription(
        tierId: widget.tier.id,
        email: email,
      );
      final url = result['authorization_url'] as String?;
      final ref = result['reference'] as String?;
      if (!mounted) return;
      if (url == null || ref == null) {
        setState(() {
          _error = 'Réponse inattendue du serveur.';
          _phase = _SubscribePhase.form;
        });
        return;
      }
      _pendingReference = ref;
      // Ouvrir Paystack dans le navigateur
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      if (!mounted) return;
      setState(() => _phase = _SubscribePhase.pending);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Impossible d\'initier le paiement. Réessayez.';
        _phase = _SubscribePhase.form;
      });
    }
  }

  Future<void> _verify() async {
    if (_pendingReference == null) return;
    setState(() {
      _phase = _SubscribePhase.verifying;
      _error = null;
    });
    try {
      final active = await widget.repository.verifySubscription(
        tierId: widget.tier.id,
        reference: _pendingReference!,
      );
      if (!mounted) return;
      setState(() => _phase = active ? _SubscribePhase.success : _SubscribePhase.error);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Paiement non confirmé. Attendez quelques secondes et réessayez.';
        _phase = _SubscribePhase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: AppColors.kBorder,
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
              ),
            ),
          ),
          Text(
            'S\'abonner · ${widget.tier.name}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.kTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_fmt(widget.tier.priceMonthlyFcfa)} FCFA / mois',
            style: AppTextStyles.kBodyMedium.copyWith(
              color: AppColors.kSuccess,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          // ── Contenu selon la phase ──────────────────────────────────────
          if (_phase == _SubscribePhase.form) ...[
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Votre email',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.kError)),
            ],
            const SizedBox(height: 16),
            _ActionButton(label: 'Payer et s\'abonner', onPressed: _initiate),
          ] else if (_phase == _SubscribePhase.verifying) ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(color: AppColors.kPrimary),
              ),
            ),
          ] else if (_phase == _SubscribePhase.pending) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kPrimarySurface,
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
                border: Border.all(color: AppColors.kPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.open_in_browser_rounded,
                      color: AppColors.kPrimary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Finalisez le paiement dans le navigateur, puis revenez ici et appuyez sur Vérifier.',
                      style: AppTextStyles.kBodyMedium
                          .copyWith(color: AppColors.kPrimary),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ActionButton(label: 'J\'ai payé — Vérifier', onPressed: _verify),
          ] else if (_phase == _SubscribePhase.success) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kSuccess.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
                border: Border.all(color: AppColors.kSuccess.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.kSuccess, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Abonnement activé ! Bienvenue dans le Fan Pass.',
                      style: AppTextStyles.kBodyMedium
                          .copyWith(color: AppColors.kSuccess, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ActionButton(
              label: 'Fermer',
              onPressed: () => Navigator.of(context).pop(),
              color: AppColors.kBgElevated,
              textColor: AppColors.kTextPrimary,
            ),
          ] else if (_phase == _SubscribePhase.error) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.kError.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
                border: Border.all(color: AppColors.kError.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.error_outline_rounded,
                      color: AppColors.kError, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _error ?? 'Paiement non confirmé.',
                      style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kError),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    label: 'Réessayer',
                    onPressed: _verify,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionButton(
                    label: 'Annuler',
                    onPressed: () => Navigator.of(context).pop(),
                    color: AppColors.kBgElevated,
                    textColor: AppColors.kTextPrimary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final Color textColor;

  const _ActionButton({
    required this.label,
    required this.onPressed,
    this.color = AppColors.kPrimary,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.kButtonHeight,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          shape: const StadiumBorder(),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

String _fmt(int n) {
  if (n == 0) return '0';
  final s = n.toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write('\u202F');
    buf.write(s[i]);
  }
  return buf.toString();
}
