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
import 'package:ppv_app/features/notifications/presentation/notification_list_screen.dart';
import 'package:ppv_app/features/notifications/presentation/notification_provider.dart';
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
          // ── Header sticky ────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.kBgBase,
            floating: true,
            snap: true,
            elevation: 0,
            toolbarHeight: 68,
            flexibleSpace: FlexibleSpaceBar(background: _buildHeader(context)),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _buildBalanceSection(context),
              const SizedBox(height: 36),
              _buildPerformanceSection(),
              const SizedBox(height: 36),
              _buildRecentContentSection(context),
              const SizedBox(height: 36),
              _buildRecentPaymentsSection(),
              const SizedBox(height: 120),
            ]),
          ),
        ],
      ),
    );
  }

  // ─── Header ──────────────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Consumer2<ProfileProvider, NotificationProvider>(
      builder: (context, profile, notif, _) {
        final user = profile.user;
        final firstName = user?.firstName ?? '';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            children: [
              // ── Wordmark ──────────────────────────────────────────────
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
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
              const Spacer(),
              // ── Cloche notifications ───────────────────────────────────
              GestureDetector(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ChangeNotifierProvider.value(
                        value: notif,
                        child: const NotificationListScreen(),
                      ),
                    ),
                  );
                },
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.kBgElevated,
                        border: Border.all(color: AppColors.kBorder),
                      ),
                      child: const Icon(
                        Icons.notifications_outlined,
                        size: 20,
                        color: AppColors.kTextSecondary,
                      ),
                    ),
                    if (notif.unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: const BoxDecoration(
                            color: AppColors.kError,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              notif.unreadCount > 9
                                  ? '9+'
                                  : '${notif.unreadCount}',
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              // ── Avatar ────────────────────────────────────────────────
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
                              _avatarFallback(firstName),
                        )
                      : _avatarFallback(firstName),
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
        builder: (context, wallet, payout, child) {
          final hasPayoutMethod = payout.existingPayoutMethod?.isActive ?? false;
          final canWithdraw =
              wallet.balance > 0 && hasPayoutMethod && !wallet.isWithdrawing;
          final balanceFcfa = wallet.balance ~/ 100;

          return Column(
            children: [
              // ── Balance card ─────────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(28, 28, 28, 24),
                decoration: BoxDecoration(
                  color: AppColors.kPrimary,
                  borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.kPrimary.withValues(alpha: 0.30),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Déco : cercles translucides en arrière-plan
                    Positioned(
                      top: -20,
                      right: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30,
                      left: -10,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.kAccent.withValues(alpha: 0.10),
                        ),
                      ),
                    ),
                    // Contenu
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_rounded,
                              size: 14,
                              color: Colors.white.withValues(alpha: 0.70),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'SOLDE DISPONIBLE',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: Colors.white.withValues(alpha: 0.70),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        // Montant
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
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
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
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.kAccent
                                          .withValues(alpha: 0.20),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      'FCFA',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        color: AppColors.kAccent,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                        const SizedBox(height: 24),
                        // Bouton Retirer
                        SizedBox(
                          width: double.infinity,
                          height: AppSpacing.kButtonHeight,
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
                                  Colors.white.withValues(alpha: 0.15),
                              disabledForegroundColor:
                                  Colors.white.withValues(alpha: 0.45),
                              shape: const StadiumBorder(),
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
              const SizedBox(height: 12),
              // ── Bouton Uploader ──────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: AppSpacing.kButtonHeight,
                child: OutlinedButton.icon(
                  onPressed: () => context.push(RouteNames.kRouteUpload),
                  icon: const Icon(Icons.add_circle_rounded, size: 22),
                  label: const Text('Uploader du contenu'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.kPrimary,
                    backgroundColor: AppColors.kBgSurface,
                    side: const BorderSide(
                        color: AppColors.kPrimary, width: 1.5),
                    shape: const StadiumBorder(),
                    textStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 15,
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
      builder: (context, provider, child) {
        final totalViews =
            provider.myContents.fold(0, (s, c) => s + c.viewCount);
        final totalSales =
            provider.myContents.fold(0, (s, c) => s + c.purchaseCount);
        final loading =
            provider.isFetchingContents && provider.myContents.isEmpty;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Performance', style: AppTextStyles.kTitleLarge),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.remove_red_eye_outlined,
                      iconBgColor:
                          AppColors.kPrimary.withValues(alpha: 0.10),
                      iconColor: AppColors.kPrimary,
                      label: 'Total Vues',
                      value: loading ? '…' : _fmt(totalViews),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.credit_card_rounded,
                      iconBgColor:
                          AppColors.kSuccess.withValues(alpha: 0.10),
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
      builder: (ctx, provider, child) {
        final contents = provider.myContents.take(10).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Contenus récents',
                      style: AppTextStyles.kTitleLarge),
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
            const SizedBox(height: 14),
            if (provider.isFetchingContents && contents.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child:
                      CircularProgressIndicator(color: AppColors.kPrimary),
                ),
              )
            else if (contents.isEmpty)
              const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: _EmptyState(
                  icon: Icons.image_outlined,
                  message: 'Aucun contenu publié',
                ),
              )
            else
              SizedBox(
                height: 330,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: contents.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 14),
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
      builder: (ctx, wallet, child) {
        final transactions = wallet.transactions.take(5).toList();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paiements récents', style: AppTextStyles.kTitleLarge),
              const SizedBox(height: 14),
              if (wallet.isFetchingTransactions && transactions.isEmpty)
                const Center(
                  child:
                      CircularProgressIndicator(color: AppColors.kPrimary),
                )
              else if (transactions.isEmpty)
                const _EmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: 'Aucun paiement reçu',
                )
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.kBgSurface,
                    borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
                    border: Border.all(color: AppColors.kBorder),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kTextPrimary.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < transactions.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: AppColors.kBorder.withValues(alpha: 0.5),
                            indent: 20,
                            endIndent: 20,
                          ),
                        _PaymentRow(tx: transactions[i]),
                      ],
                    ],
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

// ─── _EmptyState ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;

  const _EmptyState({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Center(
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.kBgElevated,
              ),
              child: Icon(icon, size: 22, color: AppColors.kTextTertiary),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              style: AppTextStyles.kBodyMedium
                  .copyWith(color: AppColors.kTextSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── _StatCard ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconBgColor,
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
        boxShadow: [
          BoxShadow(
            color: AppColors.kTextPrimary.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconBgColor,
            ),
            child: Icon(icon, size: 18, color: iconColor),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: AppTextStyles.kCaption
                .copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
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
      width: 260,
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
            // Gradient overlay
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.80),
                    ],
                    stops: const [0.4, 0.6, 1.0],
                  ),
                ),
              ),
            ),
            // Info bas
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
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
                    const SizedBox(height: 10),
                    Text(
                      content.slug ?? 'Contenu #${content.id}',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white,
                        fontSize: 15,
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
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${content.viewCount}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.shopping_cart_outlined,
                            color: Colors.white70, size: 13),
                        const SizedBox(width: 4),
                        Text(
                          '${content.purchaseCount} ventes',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Bouton partage — haut-droite
            Positioned(
              top: 14,
              right: 14,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.18),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22)),
                ),
                child: const Icon(
                  Icons.share_rounded,
                  color: Colors.white,
                  size: 16,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Colors.white,
          fontSize: 10,
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
        '${_fmt(price)} FCFA',
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: Colors.white,
          fontSize: 11,
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

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              // Icône wallet vert
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.kSuccess.withValues(alpha: 0.10),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: AppColors.kSuccess,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
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
              // Droite : méthode + heure
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (tx.paymentMethod != null)
                    Text(
                      tx.paymentMethod!,
                      style: AppTextStyles.kCaption.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.kTextPrimary,
                        fontSize: 12,
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
