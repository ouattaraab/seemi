import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/routing/route_names.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/auth/presentation/profile_provider.dart';
import 'package:ppv_app/features/content/domain/content.dart';
import 'package:ppv_app/features/content/presentation/content_provider.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';
import 'package:ppv_app/features/wallet/domain/wallet_transaction.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/withdrawal_bottom_sheet.dart';

class HomeDashboardTab extends StatefulWidget {
  const HomeDashboardTab({super.key});

  @override
  State<HomeDashboardTab> createState() => _HomeDashboardTabState();
}

class _HomeDashboardTabState extends State<HomeDashboardTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ContentProvider>().loadMyContents(refresh: true);
      context.read<WalletProvider>().loadBalance();
      context.read<WalletProvider>().loadTransactions(refresh: true);
      context.read<PayoutMethodProvider>().loadExistingPayoutMethod();
      context.read<ProfileProvider>().loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: AppColors.kPrimary,
      onRefresh: () async {
        await Future.wait([
          context.read<ContentProvider>().loadMyContents(refresh: true),
          context.read<WalletProvider>().loadBalance(),
          context.read<WalletProvider>().loadTransactions(refresh: true),
          context.read<PayoutMethodProvider>().loadExistingPayoutMethod(),
          context.read<ProfileProvider>().loadProfile(),
        ]);
      },
      child: CustomScrollView(
        slivers: [
          // ── Header sticky ──────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.kBgBase,
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 64,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildBalanceSection(context),
              const SizedBox(height: 32),
              _buildPerformanceSection(),
              const SizedBox(height: 32),
              _buildRecentContentSection(context),
              const SizedBox(height: 32),
              _buildRecentPaymentsSection(),
              const SizedBox(height: 120), // bottom nav padding
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Consumer<ProfileProvider>(
      builder: (context, provider, _) {
        final user = provider.user;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin, vertical: 12),
          child: Row(
            children: [
              // Logo SeeMi
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 8),
              Text(
                'SeeMi',
                style: AppTextStyles.kHeadlineMedium.copyWith(
                  color: AppColors.kPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.kAccent, width: 2),
                ),
                child: ClipOval(
                  child: user?.avatarUrl != null
                      ? Image.network(user!.avatarUrl!, fit: BoxFit.cover,
                          errorBuilder: (ctx, e, st) => _avatarFallback(user.firstName ?? 'U'))
                      : _avatarFallback(user?.firstName ?? 'U'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarFallback(String name) {
    return Container(
      color: AppColors.kPrimary,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : 'U',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
        ),
      ),
    );
  }

  // ─── Balance section ─────────────────────────────────────────────────────

  Widget _buildBalanceSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin),
      child: Consumer2<WalletProvider, PayoutMethodProvider>(
        builder: (context, wallet, payout, _) {
          final hasPayoutMethod = payout.existingPayoutMethod?.isActive ?? false;
          final canWithdraw = wallet.balance > 0 && hasPayoutMethod && !wallet.isWithdrawing;
          final balanceFcfa = wallet.balance ~/ 100;

          return Column(
            children: [
              // Carte solde
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary,
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
                ),
                child: Column(
                  children: [
                    Text(
                      'Solde disponible',
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Balance
                    wallet.isLoading
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: _formatBalance(balanceFcfa),
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: Colors.white,
                                    fontSize: 48,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -1,
                                    height: 1.1,
                                  ),
                                ),
                                const TextSpan(
                                  text: ' FCFA',
                                  style: TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: AppColors.kAccent,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                    const SizedBox(height: 24),
                    // Bouton Retirer
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        key: const Key('btn-withdraw'),
                        onPressed: canWithdraw
                            ? () {
                                wallet.clearWithdrawalError();
                                showModalBottomSheet<void>(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: AppColors.kBgSurface,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(AppSpacing.kRadiusXl),
                                    ),
                                  ),
                                  builder: (_) => const WithdrawalBottomSheet(),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.account_balance_wallet_rounded, size: 20),
                        label: const Text('Retirer mes gains'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.white.withValues(alpha: 0.2),
                          disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Bouton Uploader
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(RouteNames.kRouteUpload),
                  icon: const Icon(Icons.add_circle_rounded, color: AppColors.kAccent, size: 24),
                  label: const Text('Uploader du contenu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.kTextPrimary,
                    side: const BorderSide(color: AppColors.kAccent, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatBalance(int fcfa) {
    if (fcfa == 0) return '0';
    final str = fcfa.toString();
    final buffer = StringBuffer();
    final len = str.length;
    for (var i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) buffer.write(',');
      buffer.write(str[i]);
    }
    return buffer.toString();
  }

  // ─── Performance section ──────────────────────────────────────────────────

  Widget _buildPerformanceSection() {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        final totalViews = provider.myContents.fold(0, (s, c) => s + c.viewCount);
        final totalSales = provider.myContents.fold(0, (s, c) => s + c.purchaseCount);
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Performance', style: AppTextStyles.kTitleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.visibility_outlined,
                      iconColor: AppColors.kTextSecondary,
                      label: 'Total Vues',
                      value: provider.isFetchingContents ? '…' : _formatBalance(totalViews),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.credit_card_rounded,
                      iconColor: AppColors.kSuccess,
                      label: 'Total Ventes',
                      value: provider.isFetchingContents ? '…' : _formatBalance(totalSales),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Recent content section ───────────────────────────────────────────────

  Widget _buildRecentContentSection(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (ctx, provider, _) {
        final contents = provider.myContents.take(10).toList();
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Contenus récents', style: AppTextStyles.kTitleLarge),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Voir tout'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (provider.isFetchingContents && contents.isEmpty)
              const Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(color: AppColors.kPrimary),
              )
            else if (contents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin, vertical: 16),
                child: Text(
                  'Aucun contenu publié',
                  style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
                ),
              )
            else
              SizedBox(
                height: 350,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin),
                  itemCount: contents.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 12),
                  itemBuilder: (context, i) => _ContentCard(content: contents[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  // ─── Recent payments section ──────────────────────────────────────────────

  Widget _buildRecentPaymentsSection() {
    return Consumer<WalletProvider>(
      builder: (ctx, wallet, _) {
        final transactions = wallet.transactions.take(5).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.kScreenMargin),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paiements récents', style: AppTextStyles.kTitleLarge),
              const SizedBox(height: 12),
              if (wallet.isFetchingTransactions && transactions.isEmpty)
                const Center(child: CircularProgressIndicator(color: AppColors.kPrimary))
              else if (transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.kBgSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
                    border: Border.all(color: AppColors.kBorder.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      'Aucun paiement reçu',
                      style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
                    ),
                  ),
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.kBgSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
                    border: Border.all(color: AppColors.kAccent.withValues(alpha: 0.15)),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length,
                    separatorBuilder: (context, index) => const Divider(height: 1, indent: 72),
                    itemBuilder: (context, i) => _PaymentRow(tx: transactions[i]),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ─── _StatCard ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Text(label, style: AppTextStyles.kCaption.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.kHeadlineMedium.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}

// ─── _ContentCard ─────────────────────────────────────────────────────────────

class _ContentCard extends StatelessWidget {
  final Content content;
  const _ContentCard({required this.content});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        child: Stack(
          children: [
            // Image de fond
            Positioned.fill(
              child: content.blurUrl != null
                  ? Image.network(
                      content.blurUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) => Container(color: AppColors.kBgElevated),
                    )
                  : Container(
                      color: AppColors.kBgElevated,
                      child: const Icon(Icons.image_outlined, size: 48, color: AppColors.kTextTertiary),
                    ),
            ),
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.2),
                      Colors.black.withValues(alpha: 0.8),
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Info en bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StatusBadge(status: content.status),
                        if (content.price != null)
                          _PriceBadge(price: content.price! ~/ 100),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content.slug ?? 'Contenu #${content.id}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text('${content.viewCount}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                        const SizedBox(width: 12),
                        const Icon(Icons.shopping_cart_outlined, color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text('${content.purchaseCount} ventes', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                      ],
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
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        status == 'active' ? 'Actif' : status == 'pending' ? 'En attente' : status,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PriceBadge extends StatelessWidget {
  final int price;
  const _PriceBadge({required this.price});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.kAccent,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      child: Text(
        '$price FCFA',
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ─── _PaymentRow ──────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final WalletTransaction tx;
  const _PaymentRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final isCredit = tx.type == 'credit';
    final amount = tx.amount ~/ 100;
    final sign = isCredit ? '+' : '-';
    final color = isCredit ? AppColors.kSuccess : AppColors.kPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icône
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Description
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCredit ? 'Paiement reçu' : 'Retrait',
                  style: AppTextStyles.kBodyLarge.copyWith(fontWeight: FontWeight.w700),
                ),
                Text(
                  tx.description ?? tx.buyerEmail ?? '—',
                  style: AppTextStyles.kCaption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          // Montant + méthode
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign$amount',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                tx.paymentMethod ?? '',
                style: AppTextStyles.kCaption.copyWith(fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
