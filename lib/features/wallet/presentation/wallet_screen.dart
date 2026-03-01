import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/core/theme/app_spacing.dart';
import 'package:ppv_app/core/theme/app_text_styles.dart';
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
            // Header
            SliverToBoxAdapter(child: _buildHeader()),
            // Balance card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: _buildBalanceCard(context),
              ),
            ),
            // Payout methods
            SliverToBoxAdapter(child: _buildPayoutMethodsSection()),
            // Recent activity
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: _buildActivitySection(),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 80)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Portefeuille', style: AppTextStyles.kHeadlineLarge),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.kBgElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.settings_rounded, color: AppColors.kTextPrimary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context) {
    return Consumer2<WalletProvider, PayoutMethodProvider>(
      builder: (context, wallet, payout, _) {
        final hasPayoutMethod = payout.existingPayoutMethod?.isActive ?? false;
        final canWithdraw = wallet.balance > 0 && hasPayoutMethod && !wallet.isWithdrawing;
        final balanceFcfa = wallet.balance ~/ 100;

        return Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            color: AppColors.kPrimary,
            borderRadius: BorderRadius.circular(40),
          ),
          child: Column(
            children: [
              Text(
                'Solde disponible',
                style: AppTextStyles.kCaption.copyWith(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              wallet.isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _fmt(balanceFcfa),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -1,
                            ),
                          ),
                          const TextSpan(
                            text: ' FCFA',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              color: AppColors.kAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
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
                              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
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
                    disabledBackgroundColor: Colors.white.withValues(alpha: 0.15),
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSpacing.kRadiusPill),
                    ),
                    elevation: 0,
                    textStyle: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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

  Widget _buildPayoutMethodsSection() {
    return Consumer<PayoutMethodProvider>(
      builder: (context, provider, _) {
        final method = provider.existingPayoutMethod;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Méthodes de retrait', style: AppTextStyles.kTitleLarge),
                  TextButton(
                    onPressed: () {},
                    child: const Text('+ Ajouter'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  if (method != null)
                    _PayoutMethodCard(
                      name: method.payoutType == 'mobile_money' ? 'Mobile Money' : method.payoutType,
                      detail: '•••• ${method.accountNumberMasked.length > 4 ? method.accountNumberMasked.substring(method.accountNumberMasked.length - 4) : method.accountNumberMasked}',
                      isActive: method.isActive,
                    )
                  else
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

  Widget _buildActivitySection() {
    return Consumer<WalletProvider>(
      builder: (context, wallet, _) {
        final txItems = wallet.transactions
            .map((tx) => _ActivityRow.fromTransaction(tx))
            .toList();
        final wItems = wallet.withdrawals
            .map((w) => _ActivityRow.fromWithdrawal(w))
            .toList();
        final items = [...txItems, ...wItems];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Activité récente', style: AppTextStyles.kTitleLarge),
            const SizedBox(height: 12),
            if (wallet.isFetchingTransactions && items.isEmpty)
              const Center(child: CircularProgressIndicator(color: AppColors.kPrimary))
            else if (items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Aucune activité',
                    style: AppTextStyles.kBodyMedium.copyWith(color: AppColors.kTextSecondary),
                  ),
                ),
              )
            else
              ...items.map(
                (w) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: w,
                ),
              ),
            if (wallet.hasMoreTransactions)
              Center(
                child: TextButton(
                  onPressed: () => wallet.loadTransactions(),
                  child: const Text(
                    'CHARGER PLUS',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: AppColors.kTextSecondary,
                    ),
                  ),
                ),
              ),
          ],
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
  final String name;
  final String detail;
  final bool isActive;

  const _PayoutMethodCard({
    required this.name,
    required this.detail,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(
          color: isActive ? AppColors.kAccent.withValues(alpha: 0.3) : AppColors.kBorder,
          width: 1.5,
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
                  color: const Color(0xFFFF6600),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                    'O',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ),
              if (isActive)
                const Icon(Icons.check_circle_rounded, color: AppColors.kAccent, size: 24),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTextStyles.kBodyLarge.copyWith(fontWeight: FontWeight.w700)),
              Text(detail, style: AppTextStyles.kCaption),
            ],
          ),
        ],
      ),
    );
  }
}

class _AddPayoutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.kBgElevated,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder, width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_rounded, color: AppColors.kPrimary, size: 32),
          const SizedBox(height: 8),
          Text(
            'Ajouter un moyen\nde retrait',
            style: AppTextStyles.kCaption.copyWith(
              color: AppColors.kPrimary,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─── _ActivityRow ─────────────────────────────────────────────────────────────

class _ActivityRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final String dateMethod;
  final int amountCentimes;
  final bool isCredit;
  final bool isWithdrawal;

  const _ActivityRow({
    required this.title,
    required this.subtitle,
    required this.dateMethod,
    required this.amountCentimes,
    required this.isCredit,
    this.isWithdrawal = false,
  });

  factory _ActivityRow.fromTransaction(WalletTransaction tx) {
    final isCredit = tx.type == 'credit';
    return _ActivityRow(
      title: isCredit ? 'Paiement reçu' : 'Débit',
      subtitle: tx.description ?? tx.buyerEmail ?? '—',
      dateMethod: '${_fmtDate(tx.createdAt)} • ${tx.paymentMethod ?? ''}',
      amountCentimes: tx.amount,
      isCredit: isCredit,
    );
  }

  factory _ActivityRow.fromWithdrawal(WithdrawalSummary w) {
    return _ActivityRow(
      title: 'Retrait',
      subtitle: w.payoutMethodLabel ?? 'Envoyé',
      dateMethod: '${_fmtDate(w.createdAt)} • ${w.status}',
      amountCentimes: w.amount,
      isCredit: false,
      isWithdrawal: true,
    );
  }

  static String _fmtDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
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

  @override
  Widget build(BuildContext context) {
    final color = isCredit
        ? AppColors.kSuccess
        : (isWithdrawal ? AppColors.kPrimary : AppColors.kError);
    final sign = isCredit ? '+' : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(AppSpacing.kRadiusXl),
        border: Border.all(color: AppColors.kBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isCredit ? Icons.south_west_rounded : Icons.north_east_rounded,
              color: color,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.kBodyLarge.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTextStyles.kCaption, maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(dateMethod, style: AppTextStyles.kCaption.copyWith(fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$sign${_fmtAmt(amountCentimes)}',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: color,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text('après frais', style: AppTextStyles.kCaption.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }
}
