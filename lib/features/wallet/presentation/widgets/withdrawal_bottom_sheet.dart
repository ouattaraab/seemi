import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/features/payout/domain/payout_method.dart';
import 'package:ppv_app/features/payout/presentation/payout_method_provider.dart';
import 'package:ppv_app/features/wallet/presentation/wallet_provider.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/wallet_card.dart';

/// Bottom sheet de demande de retrait.
///
/// Affiche le solde disponible, le moyen de reversement actif, et un champ
/// de saisie du montant (en FCFA). Soumet via [WalletProvider.requestWithdrawal].
class WithdrawalBottomSheet extends StatefulWidget {
  const WithdrawalBottomSheet({super.key});

  @override
  State<WithdrawalBottomSheet> createState() => _WithdrawalBottomSheetState();
}

class _WithdrawalBottomSheetState extends State<WithdrawalBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _payoutMethodLabel(PayoutMethod method) {
    final type = method.payoutType == 'mobile_money' ? 'Mobile Money' : 'Compte bancaire';
    final provider = method.provider != null
        ? '${_capitalizeFirst(method.provider!)} — '
        : '';
    return '$provider$type — ${method.accountNumberMasked}';
  }

  String _capitalizeFirst(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Future<void> _submit(
    WalletProvider walletProvider,
    PayoutMethod payoutMethod,
  ) async {
    if (!_formKey.currentState!.validate()) return;

    final amountFcfa = int.tryParse(_amountController.text.trim()) ?? 0;
    final amountCentimes = amountFcfa * 100;

    final success = await walletProvider.requestWithdrawal(
      amountCentimes: amountCentimes,
      payoutMethodId: payoutMethod.id,
    );

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Demande de retrait envoyée'),
          backgroundColor: AppColors.kSuccess,
        ),
      );
    }
    // En cas d'erreur, le message est affiché dans le sheet via Consumer
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        final payoutProvider = context.read<PayoutMethodProvider>();
        final payoutMethod = payoutProvider.existingPayoutMethod;
        final balanceFcfa = walletProvider.balance ~/ 100;

        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ─── Titre ────────────────────────────────────────────────
                const Text(
                  'Retirer des gains',
                  style: TextStyle(
                    color: AppColors.kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 20),

                // ─── Solde disponible ─────────────────────────────────────
                _InfoRow(
                  label: 'Solde disponible',
                  value: WalletCard.formatAmount(balanceFcfa),
                  key: const Key('withdrawal-balance-display'),
                ),
                const SizedBox(height: 12),

                // ─── Moyen de reversement ─────────────────────────────────
                if (payoutMethod != null)
                  _InfoRow(
                    label: 'Moyen de reversement',
                    value: _payoutMethodLabel(payoutMethod),
                    key: const Key('withdrawal-payout-method-display'),
                  ),
                const SizedBox(height: 20),

                // ─── Champ montant ────────────────────────────────────────
                TextFormField(
                  key: const Key('withdrawal-amount-input'),
                  controller: _amountController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  style: const TextStyle(color: AppColors.kTextPrimary),
                  decoration: InputDecoration(
                    labelText: 'Montant à retirer',
                    labelStyle: const TextStyle(color: AppColors.kTextSecondary),
                    suffixText: 'FCFA',
                    suffixStyle: const TextStyle(color: AppColors.kTextSecondary),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.kOutline),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.kPrimary),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.kError),
                    ),
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: AppColors.kError),
                    ),
                  ),
                  validator: (value) {
                    final amount = int.tryParse(value?.trim() ?? '');
                    if (amount == null || amount <= 0) {
                      return 'Veuillez saisir un montant valide';
                    }
                    if (amount < 500) {
                      return 'Minimum : 500 FCFA';
                    }
                    if (amount > balanceFcfa) {
                      return 'Montant supérieur au solde disponible';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ─── Erreur API ───────────────────────────────────────────
                if (walletProvider.withdrawalError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      walletProvider.withdrawalError!,
                      style: const TextStyle(
                        color: AppColors.kError,
                        fontSize: 13,
                      ),
                    ),
                  ),

                // ─── Bouton Confirmer ─────────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    key: const Key('btn-confirm-withdrawal'),
                    onPressed: (walletProvider.isWithdrawing || payoutMethod == null)
                        ? null
                        : () => _submit(walletProvider, payoutMethod),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.kPrimary,
                      disabledBackgroundColor: const Color(0xFF2C2C2E),
                      disabledForegroundColor: const Color(0xFF666666),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: walletProvider.isWithdrawing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Confirmer',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Widget helper pour afficher une ligne label / valeur.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.kTextSecondary, fontSize: 13),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.kTextPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
