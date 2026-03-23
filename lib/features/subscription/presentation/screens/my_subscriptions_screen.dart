import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/subscription/data/subscription_repository.dart';
import 'package:provider/provider.dart';

class MySubscriptionsScreen extends StatefulWidget {
  const MySubscriptionsScreen({super.key});

  @override
  State<MySubscriptionsScreen> createState() => _MySubscriptionsScreenState();
}

class _MySubscriptionsScreenState extends State<MySubscriptionsScreen> {
  List<ActiveSubscription> _subs = [];
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
      _subs = await context.read<SubscriptionRepository>().mySubscriptions();
    } catch (_) {
      _error = 'Impossible de charger vos abonnements.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        title: const Text(
          'Mes abonnements',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
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
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _error!,
                        style: AppTextStyles.kBodyMedium
                            .copyWith(color: AppColors.kTextSecondary),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: _load,
                        child: const Text(
                          'Réessayer',
                          style: TextStyle(color: AppColors.kPrimary),
                        ),
                      ),
                    ],
                  ),
                )
              : _subs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.card_membership_rounded,
                            size: 48,
                            color: AppColors.kTextTertiary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Aucun abonnement actif.',
                            style: AppTextStyles.kBodyMedium
                                .copyWith(color: AppColors.kTextSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(20),
                        itemCount: _subs.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 12),
                        itemBuilder: (_, i) {
                          final sub = _subs[i];
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.kBgSurface,
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.kRadiusLg),
                              border: Border.all(color: AppColors.kBorder),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sub.tierName ?? 'Fan Pass',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.kTextPrimary,
                                  ),
                                ),
                                if (sub.creatorName != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    sub.creatorName!,
                                    style: AppTextStyles.kBodyMedium.copyWith(
                                      color: AppColors.kTextSecondary,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${sub.priceMonthlyFcfa} FCFA/mois',
                                      style: AppTextStyles.kBodyMedium
                                          .copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.kSuccess,
                                      ),
                                    ),
                                    if (sub.expiresAt != null)
                                      Text(
                                        'Expire le ${_fmtDate(sub.expiresAt!)}',
                                        style: AppTextStyles.kCaption.copyWith(
                                          color: AppColors.kTextTertiary,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }
}
