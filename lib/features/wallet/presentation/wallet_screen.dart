import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
import 'package:ppv_app/features/payout/domain/payout_method.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';
import 'package:ppv_app/features/wallet/domain/wallet_transaction.dart';
import 'package:ppv_app/features/wallet/domain/withdrawal_summary.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/withdrawal_bottom_sheet.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final wallet = context.read<WalletProvider>();
      wallet.loadBalance();
      wallet.loadTransactions(refresh: true);
      wallet.loadWithdrawals();
      context.read<PayoutMethodProvider>().loadExistingPayoutMethod();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        color: AppColors.kPrimary,
        onRefresh: () async {
          final wallet = context.read<WalletProvider>();
          await Future.wait([
            wallet.loadBalance(),
            wallet.loadTransactions(refresh: true),
            wallet.loadWithdrawals(),
            context.read<PayoutMethodProvider>().loadExistingPayoutMethod(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: _buildBalanceCard(context),
              ),
            ),
            SliverToBoxAdapter(child: _buildPayoutMethodsSection()),
            SliverToBoxAdapter(child: _buildActivitySection()),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Portefeuille', style: AppTextStyles.kHeadlineLarge),
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AppColors.kBgElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.settings_rounded,
              color: AppColors.kTextSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  // ── Balance card ──────────────────────────────────────────────────────────

  Widget _buildBalanceCard(BuildContext context) {
    return Consumer2<WalletProvider, PayoutMethodProvider>(
      builder: (context, wallet, payout, child) {
        final hasPayoutMethod = payout.existingPayoutMethod?.isActive ?? false;
        final canWithdraw =
            wallet.balance > 0 && hasPayoutMethod && !wallet.isWithdrawing;
        final balanceFcfa = wallet.balance ~/ 100;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          decoration: BoxDecoration(
            color: AppColors.kPrimary,
            borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
            boxShadow: [
              BoxShadow(
                color: AppColors.kPrimary.withValues(alpha: 0.30),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Orbe déco — haut droite
              Positioned(
                top: -32,
                right: -32,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.kAccent.withValues(alpha: 0.18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.kAccent.withValues(alpha: 0.20),
                        blurRadius: 50,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                ),
              ),
              // Orbe déco — bas gauche
              Positioned(
                bottom: -24,
                left: -24,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              // Contenu
              Column(
                children: [
                  // Label
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'SOLDE DISPONIBLE',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Montant
                  wallet.isLoading
                      ? const SizedBox(
                          height: 60,
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
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                letterSpacing: -1.5,
                                height: 1.0,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.kAccent.withValues(alpha: 0.22),
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
                  const SizedBox(height: 28),
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
                                      top: Radius.circular(32)),
                                ),
                                builder: (_) => const WithdrawalBottomSheet(),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.account_balance_rounded, size: 20),
                      label: const Text('Retirer mes gains'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.kAccent,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            Colors.white.withValues(alpha: 0.15),
                        disabledForegroundColor:
                            Colors.white.withValues(alpha: 0.40),
                        shape: const StadiumBorder(),
                        elevation: 0,
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
            ],
          ),
        );
      },
    );
  }

  // ── Payout Methods section ────────────────────────────────────────────────

  Widget _buildPayoutMethodsSection() {
    return Consumer<PayoutMethodProvider>(
      builder: (context, provider, child) {
        final method = provider.existingPayoutMethod;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Méthodes de retrait',
                      style: AppTextStyles.kTitleLarge),
                  TextButton(
                    onPressed: () {},
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      '+ Ajouter',
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
            SizedBox(
              height: 144,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (method != null) ...[
                    _PayoutMethodCard(method: method),
                    const SizedBox(width: 12),
                  ],
                  const _AddPayoutCard(),
                ],
              ),
            ),
            const SizedBox(height: 36),
          ],
        );
      },
    );
  }

  // ── Activité récente ──────────────────────────────────────────────────────

  Widget _buildActivitySection() {
    return Consumer<WalletProvider>(
      builder: (context, wallet, child) {
        final items = [
          ...wallet.transactions.map(_ActivityItem.fromTransaction),
          ...wallet.withdrawals.map(_ActivityItem.fromWithdrawal),
        ];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Activité récente', style: AppTextStyles.kTitleLarge),
              const SizedBox(height: 14),
              if (wallet.isFetchingTransactions && items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32),
                    child: CircularProgressIndicator(
                        color: AppColors.kPrimary),
                  ),
                )
              else if (items.isEmpty)
                _buildEmptyActivity()
              else
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.kBgSurface,
                    borderRadius:
                        BorderRadius.circular(AppSpacing.kRadiusXl),
                    border: Border.all(color: AppColors.kBorder),
                    boxShadow: [
                      BoxShadow(
                        color:
                            AppColors.kTextPrimary.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      for (var i = 0; i < items.length; i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: AppColors.kBorder.withValues(alpha: 0.6),
                            indent: 20,
                            endIndent: 20,
                          ),
                        _ActivityRow(item: items[i]),
                      ],
                    ],
                  ),
                ),
              if (wallet.hasMoreTransactions) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => wallet.loadTransactions(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.kTextSecondary,
                      side: const BorderSide(color: AppColors.kBorder),
                      shape: const StadiumBorder(),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      textStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    child: const Text('CHARGER L\'HISTORIQUE'),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyActivity() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.kBgElevated,
            ),
            child: const Icon(
              Icons.receipt_long_outlined,
              size: 24,
              color: AppColors.kTextTertiary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Aucune activité',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.kTextSecondary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Vos transactions apparaîtront ici',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: AppColors.kTextTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
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

// ─── _PayoutMethodCard ────────────────────────────────────────────────────────

class _PayoutMethodCard extends StatelessWidget {
  final PayoutMethod method;

  const _PayoutMethodCard({required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(
          color: method.isActive
              ? AppColors.kAccent.withValues(alpha: 0.30)
              : AppColors.kBorder,
          width: method.isActive ? 1.5 : 1.0,
        ),
        boxShadow: method.isActive
            ? [
                BoxShadow(
                  color: AppColors.kAccent.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _badgeColor(),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    _badgeLabel(),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: _isOrange() ? 20 : 15,
                      fontStyle: _isOrange()
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
              ),
              if (method.isActive)
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.kSuccess.withValues(alpha: 0.12),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.kSuccess,
                    size: 16,
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _providerName(),
                style: AppTextStyles.kBodyLarge
                    .copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 2),
              Text(
                method.accountNumberMasked,
                style: AppTextStyles.kCaption,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _isOrange() => method.provider?.toLowerCase() == 'orange';

  String _providerName() {
    return switch (method.provider?.toLowerCase()) {
      'orange' => 'Orange Money',
      'wave'   => 'Wave',
      'mtn'    => 'MTN Money',
      'moov'   => 'Moov Money',
      _        => method.payoutType == 'mobile_money'
          ? 'Mobile Money'
          : 'Compte bancaire',
    };
  }

  Color _badgeColor() {
    return switch (method.provider?.toLowerCase()) {
      'orange' => const Color(0xFFFF6600),
      'wave'   => const Color(0xFF1A73E8),
      'mtn'    => const Color(0xFFFFCC00),
      'moov'   => const Color(0xFF0066CC),
      _        => AppColors.kPrimary,
    };
  }

  String _badgeLabel() {
    return switch (method.provider?.toLowerCase()) {
      'orange' => 'O',
      'wave'   => 'W',
      'mtn'    => 'M',
      'moov'   => 'Mv',
      _        => method.payoutType == 'mobile_money' ? 'MM' : 'B',
    };
  }
}

// ─── _AddPayoutCard ───────────────────────────────────────────────────────────

class _AddPayoutCard extends StatelessWidget {
  const _AddPayoutCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(
          color: AppColors.kBorder,
          // Simulated dashed appearance via slightly thicker border
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.kPrimary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.kPrimary.withValues(alpha: 0.20),
                    ),
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: AppColors.kPrimary,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Ajouter un moyen',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.kTextPrimary,
                    height: 1.3,
                  ),
                ),
                const Text(
                  'de retrait',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 13,
                    color: AppColors.kTextSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── _ActivityItem (data class) ───────────────────────────────────────────────

class _ActivityItem {
  final String title;
  final String subtitle;
  final String dateMethod;
  final int amountCentimes;
  final bool isCredit;
  final bool isWithdrawal;
  final String? statusLabel;
  final String? withdrawalStatus;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.dateMethod,
    required this.amountCentimes,
    required this.isCredit,
    this.isWithdrawal = false,
    this.statusLabel,
    this.withdrawalStatus,
  });

  factory _ActivityItem.fromTransaction(WalletTransaction tx) {
    final isCredit = tx.type == 'credit';
    return _ActivityItem(
      title: isCredit ? 'Paiement reçu' : 'Débit',
      subtitle: tx.description ?? tx.buyerEmail ?? '—',
      dateMethod: _formatDateMethod(tx.createdAt, tx.paymentMethod),
      amountCentimes: tx.amount,
      isCredit: isCredit,
      statusLabel: isCredit ? 'après frais' : null,
    );
  }

  factory _ActivityItem.fromWithdrawal(WithdrawalSummary w) {
    final label = switch (w.status) {
      'completed'  => 'Succès',
      'pending'    => 'En attente',
      'processing' => 'En cours',
      'rejected'   => 'Rejeté',
      _            => w.status,
    };
    return _ActivityItem(
      title: 'Retrait',
      subtitle: w.payoutMethodLabel ?? 'Envoyé',
      dateMethod: _fmtDate(w.createdAt),
      amountCentimes: w.amount,
      isCredit: false,
      isWithdrawal: true,
      statusLabel: label,
      withdrawalStatus: w.status,
    );
  }

  static String _formatDateMethod(DateTime dt, String? method) {
    final date = _fmtDate(dt);
    return method != null ? '$date • $method' : date;
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month - 1]} ${dt.day}, $h:$min';
  }
}

// ─── _ActivityRow ─────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;
  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final iconColor = item.isCredit
        ? AppColors.kSuccess
        : (item.isWithdrawal ? AppColors.kPrimary : AppColors.kError);
    final sign = item.isCredit ? '+' : '−';
    final amtColor = item.isCredit ? AppColors.kSuccess : AppColors.kTextPrimary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Icône
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              item.isCredit
                  ? Icons.south_west_rounded
                  : Icons.north_east_rounded,
              color: iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          // Infos texte
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.kBodyMedium
                      .copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: AppTextStyles.kCaption,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  item.dateMethod,
                  style: AppTextStyles.kCaption.copyWith(
                    fontSize: 11,
                    color: AppColors.kTextTertiary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Montant + statut
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${_fmtAmt(item.amountCentimes)} F',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: amtColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (item.statusLabel != null) ...[
                const SizedBox(height: 4),
                _WithdrawalBadge(
                  label: item.statusLabel!,
                  status: item.withdrawalStatus,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtAmt(int c) {
    final n = c ~/ 100;
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

// ─── _WithdrawalBadge ─────────────────────────────────────────────────────────

class _WithdrawalBadge extends StatelessWidget {
  final String label;
  final String? status;
  const _WithdrawalBadge({required this.label, this.status});

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (status) {
      'completed'                 => (AppColors.kSuccess.withValues(alpha: 0.10), AppColors.kSuccess),
      'pending' || 'processing'  => (AppColors.kAccent.withValues(alpha: 0.10), AppColors.kAccentDark),
      'rejected'                 => (AppColors.kError.withValues(alpha: 0.10), AppColors.kError),
      _                          => (AppColors.kBgElevated, AppColors.kTextSecondary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
