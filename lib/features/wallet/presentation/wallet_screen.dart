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
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
              color: AppColors.kTextPrimary,
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
      builder: (context, wallet, payout, _) {
        final hasPayoutMethod = payout.existingPayoutMethod?.isActive ?? false;
        final canWithdraw = wallet.balance > 0 && hasPayoutMethod && !wallet.isWithdrawing;
        final balanceFcfa = wallet.balance ~/ 100;

        return ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: Container(
            padding: const EdgeInsets.all(40),
            color: AppColors.kPrimary,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Decorative orb — top-right (amber/20, blur-3xl)
                Positioned(
                  top: -40,
                  right: -40,
                  child: Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.kAccent.withValues(alpha: 0.20),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.kAccent.withValues(alpha: 0.25),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                // Decorative orb — bottom-left (amber/10, blur-2xl)
                Positioned(
                  bottom: -40,
                  left: -40,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.kAccent.withValues(alpha: 0.10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.kAccent.withValues(alpha: 0.12),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                ),
                // Content (z-10)
                Column(
                  children: [
                    // Label
                    const Text(
                      'SOLDE DISPONIBLE',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Amount + FCFA
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
                    const SizedBox(height: 32),
                    // Withdraw button
                    SizedBox(
                      width: double.infinity,
                      height: 58,
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
                                    borderRadius:
                                        BorderRadius.vertical(top: Radius.circular(32)),
                                  ),
                                  builder: (_) => const WithdrawalBottomSheet(),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.account_balance_rounded, size: 22),
                        label: const Text('Retirer mes gains'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.kAccent,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              Colors.white.withValues(alpha: 0.15),
                          disabledForegroundColor:
                              Colors.white.withValues(alpha: 0.40),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppSpacing.kRadiusPill),
                          ),
                          elevation: 0,
                          shadowColor: AppColors.kAccent.withValues(alpha: 0.30),
                          textStyle: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Payout Methods section ────────────────────────────────────────────────

  Widget _buildPayoutMethodsSection() {
    return Consumer<PayoutMethodProvider>(
      builder: (context, provider, _) {
        final method = provider.existingPayoutMethod;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Méthodes de retrait', style: AppTextStyles.kTitleLarge),
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
            const SizedBox(height: 12),
            SizedBox(
              height: 148,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (method != null) ...[
                    _PayoutMethodCard(method: method),
                    const SizedBox(width: 12),
                  ],
                  _AddPayoutCard(),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        );
      },
    );
  }

  // ── Recent activity section ───────────────────────────────────────────────

  Widget _buildActivitySection() {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
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
              const SizedBox(height: 12),
              if (wallet.isFetchingTransactions && items.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: AppColors.kPrimary),
                  ),
                )
              else if (items.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(
                      'Aucune activité',
                      style: AppTextStyles.kBodyMedium.copyWith(
                        color: AppColors.kTextSecondary,
                      ),
                    ),
                  ),
                )
              else
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _ActivityRow(item: item),
                  ),
                ),
              if (wallet.hasMoreTransactions)
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => wallet.loadTransactions(),
                    child: const Text(
                      'CHARGER L\'HISTORIQUE',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.kTextSecondary,
                        letterSpacing: 1.5,
                      ),
                    ),
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

// ─── _PayoutMethodCard ────────────────────────────────────────────────────────

class _PayoutMethodCard extends StatelessWidget {
  final PayoutMethod method;

  const _PayoutMethodCard({required this.method});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(
          color: method.isActive
              ? AppColors.kAccent.withValues(alpha: 0.20)
              : AppColors.kBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _badgeColor(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    _badgeLabel(),
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: _isOrange() ? 18 : 14,
                      fontStyle:
                          _isOrange() ? FontStyle.italic : FontStyle.normal,
                    ),
                  ),
                ),
              ),
              if (method.isActive)
                const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.kAccent,
                  size: 24,
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
              Text(method.accountNumberMasked, style: AppTextStyles.kCaption),
            ],
          ),
        ],
      ),
    );
  }

  bool _isOrange() => method.provider?.toLowerCase() == 'orange';

  String _providerName() {
    switch (method.provider?.toLowerCase()) {
      case 'orange':
        return 'Orange Money';
      case 'wave':
        return 'Wave';
      case 'mtn':
        return 'MTN Money';
      case 'moov':
        return 'Moov Money';
      default:
        return method.payoutType == 'mobile_money'
            ? 'Mobile Money'
            : 'Compte bancaire';
    }
  }

  Color _badgeColor() {
    switch (method.provider?.toLowerCase()) {
      case 'orange':
        return const Color(0xFFFF6600);
      case 'wave':
        return const Color(0xFF3399FF);
      case 'mtn':
        return const Color(0xFFFFCC00);
      case 'moov':
        return const Color(0xFF0066CC);
      default:
        return AppColors.kPrimary;
    }
  }

  String _badgeLabel() {
    switch (method.provider?.toLowerCase()) {
      case 'orange':
        return 'O';
      case 'wave':
        return 'W';
      case 'mtn':
        return 'M';
      case 'moov':
        return 'Mv';
      default:
        return method.payoutType == 'mobile_money' ? 'MM' : 'B';
    }
  }
}

// ─── _AddPayoutCard ───────────────────────────────────────────────────────────

class _AddPayoutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.kBgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.add_rounded, color: AppColors.kPrimary, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            'Ajouter un moyen',
            style: AppTextStyles.kCaption.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.kTextPrimary,
            ),
          ),
          Text(
            'de retrait',
            style: AppTextStyles.kCaption.copyWith(color: AppColors.kTextSecondary),
          ),
        ],
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

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.dateMethod,
    required this.amountCentimes,
    required this.isCredit,
    this.isWithdrawal = false,
    this.statusLabel,
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
      dateMethod: '${_fmtDate(w.createdAt)} • $label',
      amountCentimes: w.amount,
      isCredit: false,
      isWithdrawal: true,
      statusLabel: label.toUpperCase(),
    );
  }

  static String _formatDateMethod(DateTime dt, String? method) {
    final date = _fmtDate(dt);
    return method != null ? '$date • $method' : date;
  }

  static String _fmtDate(DateTime dt) {
    const m = [
      'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Juin',
      'Juil', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc',
    ];
    final h = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '${m[dt.month - 1]} ${dt.day}, $h:$min';
  }
}

// ─── _ActivityRow (widget) ────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final _ActivityItem item;

  const _ActivityRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final color = item.isCredit
        ? AppColors.kSuccess
        : (item.isWithdrawal ? AppColors.kPrimary : AppColors.kError);
    final sign = item.isCredit ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              item.isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          // Text info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.kBodyLarge
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
                  style: AppTextStyles.kCaption.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Amount
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${_fmtAmt(item.amountCentimes)}',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
              if (item.statusLabel != null)
                Text(
                  item.statusLabel!,
                  style: AppTextStyles.kCaption.copyWith(fontSize: 10),
                ),
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
