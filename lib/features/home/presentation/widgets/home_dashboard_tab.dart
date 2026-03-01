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
          // ── Header sticky ───────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.kBgBase,
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 64,
            flexibleSpace: FlexibleSpaceBar(background: _buildHeader()),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildBalanceSection(context),
              const SizedBox(height: 40),
              _buildPerformanceSection(),
              const SizedBox(height: 40),
              _buildRecentContentSection(context),
              const SizedBox(height: 40),
              _buildRecentPaymentsSection(),
              const SizedBox(height: 120),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // Logo circle
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.kPrimary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
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
                      ? Image.network(
                          user!.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, e, st) =>
                              _avatarFallback(user.firstName ?? 'U'),
                        )
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
      alignment: Alignment.center,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : 'U',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }

  // ─── Balance section ─────────────────────────────────────────────────────

  Widget _buildBalanceSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Consumer2<WalletProvider, PayoutMethodProvider>(
        builder: (context, wallet, payout, _) {
          final hasPayoutMethod = payout.existingPayoutMethod?.isActive ?? false;
          final canWithdraw =
              wallet.balance > 0 && hasPayoutMethod && !wallet.isWithdrawing;
          final balanceFcfa = wallet.balance ~/ 100;

          return Column(
            children: [
              // ── Balance card ────────────────────────────────────────────
              ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(32),
                  color: AppColors.kPrimary,
                  child: Stack(
                    children: [
                      // Radial gradient accent top-right (opacity 10%)
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topRight,
                              radius: 1.2,
                              colors: [
                                AppColors.kAccent.withValues(alpha: 0.18),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Content
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Label
                          Text(
                            'SOLDE DISPONIBLE',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Colors.white.withValues(alpha: 0.80),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          // Amount
                          wallet.isLoading
                              ? const SizedBox(
                                  height: 56,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      _fmt(balanceFcfa),
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -1,
                                        height: 1.0,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Padding(
                                      padding: EdgeInsets.only(top: 6),
                                      child: Text(
                                        'FCFA',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          color: AppColors.kAccent,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                          height: 1.0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          const SizedBox(height: 24),
                          // Withdraw button
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
                                            top: Radius.circular(32),
                                          ),
                                        ),
                                        builder: (_) =>
                                            const WithdrawalBottomSheet(),
                                      );
                                    }
                                  : null,
                              icon: const Icon(
                                  Icons.account_balance_wallet_rounded,
                                  size: 20),
                              label: const Text('Retirer'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.kAccent,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.white.withValues(alpha: 0.20),
                                disabledForegroundColor:
                                    Colors.white.withValues(alpha: 0.50),
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(AppSpacing.kRadiusPill),
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Upload button ───────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 58,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(RouteNames.kRouteUpload),
                  icon: const Icon(
                    Icons.add_circle_rounded,
                    color: AppColors.kAccent,
                    size: 24,
                  ),
                  label: const Text('Uploader du contenu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: AppColors.kTextPrimary,
                    side: const BorderSide(color: AppColors.kAccent, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.kRadiusPill),
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

  // ─── Performance section ─────────────────────────────────────────────────

  Widget _buildPerformanceSection() {
    return Consumer<ContentProvider>(
      builder: (context, provider, _) {
        final totalViews =
            provider.myContents.fold(0, (s, c) => s + c.viewCount);
        final totalSales =
            provider.myContents.fold(0, (s, c) => s + c.purchaseCount);
        final loading = provider.isFetchingContents && provider.myContents.isEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Performance', style: AppTextStyles.kTitleLarge),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.remove_red_eye_outlined,
                      iconColor: AppColors.kTextSecondary,
                      label: 'Total Vues',
                      value: loading ? '…' : _fmt(totalViews),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.credit_card_rounded,
                      iconColor: AppColors.kSuccess,
                      label: 'Total Ventes',
                      value: loading ? '…' : _fmt(totalSales),
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

  // ─── Recent content section ──────────────────────────────────────────────

  Widget _buildRecentContentSection(BuildContext context) {
    return Consumer<ContentProvider>(
      builder: (ctx, provider, _) {
        final contents = provider.myContents.take(10).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Contenus récents', style: AppTextStyles.kTitleLarge),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Voir tout',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (provider.isFetchingContents && contents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(color: AppColors.kPrimary),
                ),
              )
            else if (contents.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Text(
                  'Aucun contenu publié',
                  style: AppTextStyles.kBodyMedium
                      .copyWith(color: AppColors.kTextSecondary),
                ),
              )
            else
              SizedBox(
                height: 350,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: contents.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (_, i) => _ContentCard(content: contents[i]),
                ),
              ),
          ],
        );
      },
    );
  }

  // ─── Recent payments section ─────────────────────────────────────────────

  Widget _buildRecentPaymentsSection() {
    return Consumer<WalletProvider>(
      builder: (ctx, wallet, _) {
        final transactions = wallet.transactions.take(5).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paiements récents', style: AppTextStyles.kTitleLarge),
              const SizedBox(height: 12),
              if (wallet.isFetchingTransactions && transactions.isEmpty)
                const Center(
                  child: CircularProgressIndicator(color: AppColors.kPrimary),
                )
              else if (transactions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.kBgSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
                    border: Border.all(
                        color: AppColors.kBorder.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: Text(
                      'Aucun paiement reçu',
                      style: AppTextStyles.kBodyMedium
                          .copyWith(color: AppColors.kTextSecondary),
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.kBgSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
                    border: Border.all(
                        color: AppColors.kAccent.withValues(alpha: 0.20)),
                  ),
                  child: Column(
                    children: transactions
                        .map((tx) => _PaymentRow(tx: tx))
                        .toList(),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
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
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg), // 24px
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.kCaption
                      .copyWith(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.kHeadlineMedium
                .copyWith(fontWeight: FontWeight.w800),
          ),
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
            // Background image
            Positioned.fill(
              child: content.blurUrl != null
                  ? Image.network(
                      content.blurUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, st) =>
                          Container(color: AppColors.kBgElevated),
                    )
                  : Container(
                      color: AppColors.kBgElevated,
                      child: const Icon(
                        Icons.image_outlined,
                        size: 48,
                        color: AppColors.kTextTertiary,
                      ),
                    ),
            ),
            // Gradient overlay: from-black/80 via-black/20 to-transparent
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.20),
                      Colors.black.withValues(alpha: 0.80),
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Bottom info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 12),
                    Text(
                      content.slug ?? 'Contenu #${content.id}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.visibility_outlined,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${content.viewCount}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                        const SizedBox(width: 16),
                        const Icon(Icons.shopping_cart_outlined,
                            color: Colors.white70, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${content.purchaseCount} ventes',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Share button — top-right
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.20),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25)),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: 18,
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
    final label = switch (status) {
      'active'   => 'Actif',
      'pending'  => 'En attente',
      'rejected' => 'Rejeté',
      _          => status,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.20),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Text(
        label,
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
    final formatted = _fmt(price);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.kAccent,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      child: Text(
        '$formatted FCFA',
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _fmt(int n) {
    if (n == 0) return '0';
    final s = n.toString();
    final buf = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }
}

// ─── _PaymentRow ──────────────────────────────────────────────────────────────

class _PaymentRow extends StatelessWidget {
  final WalletTransaction tx;
  const _PaymentRow({required this.tx});

  @override
  Widget build(BuildContext context) {
    final amount = tx.amount ~/ 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusLg),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                // Icône rounded-full emerald
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.kSuccess.withValues(alpha: 0.10),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: AppColors.kSuccess,
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
                        '${_fmt(amount)} FCFA',
                        style: AppTextStyles.kBodyLarge
                            .copyWith(fontWeight: FontWeight.w700),
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
                // Right: payment method + time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tx.paymentMethod ?? '',
                      style: AppTextStyles.kCaption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextPrimary,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      _timeAgo(tx.createdAt),
                      style: AppTextStyles.kCaption.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
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
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
      buf.write(s[i]);
    }
    return buf.toString();
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays == 1) return 'Hier';
    return 'Il y a ${diff.inDays} j';
  }
}
