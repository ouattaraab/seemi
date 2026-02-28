import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/transaction_list_item.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/wallet_card.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/withdrawal_bottom_sheet.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/withdrawal_list_item.dart';

/// Écran Portefeuille (onglet "Gains" de la HomeScreen).
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
      final provider = context.read<WalletProvider>();
      provider.loadBalance();
      provider.loadTransactions();
      provider.loadWithdrawals();
      // Charge le moyen de reversement pour activer le bouton Retirer
      context.read<PayoutMethodProvider>().loadExistingPayoutMethod();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          backgroundColor: AppColors.kBgBase,
          appBar: AppBar(
            backgroundColor: AppColors.kBgBase,
            elevation: 0,
            title: const Text(
              'Portefeuille',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            centerTitle: true,
          ),
          body: NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollEndNotification &&
                  notification.metrics.extentAfter < 200 &&
                  provider.hasMoreTransactions &&
                  !provider.isFetchingTransactions) {
                provider.loadTransactions();
              }
              return false;
            },
            child: RefreshIndicator(
              color: AppColors.kPrimary,
              onRefresh: () async {
                await Future.wait([
                  provider.loadBalance(),
                  provider.loadTransactions(refresh: true),
                  provider.loadWithdrawals(),
                ]);
              },
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  WalletCard(
                    balanceCentimes: provider.balance,
                    isLoading: provider.isLoading,
                  ),
                  if (provider.error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      provider.error!,
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  // Total gains cumulés
                  Text(
                    '${WalletCard.formatAmount(provider.totalCredits ~/ 100)} gagnés au total',
                    key: const Key('total-credits-text'),
                    style: const TextStyle(
                      color: AppColors.kTextSecondary,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Liste des transactions
                  if (provider.isFetchingTransactions && provider.transactions.isEmpty)
                    const Center(
                      child: CircularProgressIndicator(color: AppColors.kPrimary),
                    )
                  else if (provider.transactionsError != null && provider.transactions.isEmpty)
                    Text(
                      provider.transactionsError!,
                      style: const TextStyle(color: AppColors.kError),
                    )
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.transactions.length +
                          (provider.hasMoreTransactions ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == provider.transactions.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(8),
                              child: CircularProgressIndicator(
                                color: AppColors.kPrimary,
                              ),
                            ),
                          );
                        }
                        return TransactionListItem(
                          transaction: provider.transactions[index],
                        );
                      },
                    ),
                  const SizedBox(height: 24),
                  // ─── Section Mes retraits ────────────────────────────────
                  const Padding(
                    padding: EdgeInsets.fromLTRB(0, 0, 0, 8),
                    child: Text(
                      'Mes retraits',
                      style: TextStyle(
                        color: AppColors.kTextPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (provider.isLoadingWithdrawals)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: CircularProgressIndicator(
                          color: AppColors.kPrimary,
                        ),
                      ),
                    )
                  else if (provider.withdrawals.isEmpty)
                    const Padding(
                      key: Key('withdrawals-empty'),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(
                        child: Text(
                          'Aucune demande de retrait',
                          style: TextStyle(color: AppColors.kTextSecondary),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      key: const Key('withdrawals-list'),
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: provider.withdrawals.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: AppColors.kOutline, height: 1),
                      itemBuilder: (_, index) => WithdrawalListItem(
                        withdrawal: provider.withdrawals[index],
                      ),
                    ),
                  const SizedBox(height: 24),
                  // Bouton Retirer — activé si solde > 0 ET moyen de reversement configuré
                  Builder(
                    builder: (context) {
                      final payoutProvider =
                          context.watch<PayoutMethodProvider>();
                      final hasPayoutMethod =
                          payoutProvider.existingPayoutMethod?.isActive ??
                              false;
                      final canWithdraw = provider.balance > 0 &&
                          hasPayoutMethod &&
                          !provider.isWithdrawing;

                      return SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          key: const Key('btn-withdraw'),
                          onPressed: canWithdraw
                              ? () {
                                  provider.clearWithdrawalError();
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    backgroundColor: AppColors.kBgElevated,
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.vertical(
                                        top: Radius.circular(16),
                                      ),
                                    ),
                                    builder: (_) =>
                                        const WithdrawalBottomSheet(),
                                  );
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.kPrimary,
                            disabledBackgroundColor: const Color(0xFF2C2C2E),
                            disabledForegroundColor: const Color(0xFF666666),
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Retirer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
