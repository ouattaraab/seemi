import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/subscription/data/subscription_repository.dart';

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
  final _repo = SubscriptionRepository();
  List<SubscriptionTier> _tiers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _tiers = await _repo.getTiersByCreator(widget.creatorId);
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

class _SubscribeSheet extends StatefulWidget {
  final SubscriptionTier tier;
  final SubscriptionRepository repository;

  const _SubscribeSheet({required this.tier, required this.repository});

  @override
  State<_SubscribeSheet> createState() => _SubscribeSheetState();
}

class _SubscribeSheetState extends State<_SubscribeSheet> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _subscribe() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      setState(() => _error = 'Email requis');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final result = await widget.repository
          .initiateSubscription(tierId: widget.tier.id, email: email);
      if (!mounted) return;
      nav.pop();
      // In a real app, open the Paystack URL in a WebView
      messenger.showSnackBar(
        SnackBar(
          content: Text('Paiement initié : ${result['authorization_url']}'),
        ),
      );
    } catch (_) {
      setState(() {
        _error = 'Impossible d\'initier le paiement.';
        _loading = false;
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
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'S\'abonner : ${widget.tier.name}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: AppColors.kTextPrimary,
            ),
          ),
          Text(
            '${_fmt(widget.tier.priceMonthlyFcfa)} FCFA / mois',
            style: AppTextStyles.kBodyMedium.copyWith(
              color: AppColors.kSuccess,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
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
          SizedBox(
            width: double.infinity,
            height: AppSpacing.kButtonHeight,
            child: FilledButton(
              onPressed: _loading ? null : _subscribe,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.kPrimary,
                shape: const StadiumBorder(),
              ),
              child: _loading
                  ? const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    )
                  : const Text(
                      'Payer et s\'abonner',
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
