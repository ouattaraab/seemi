import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/features/wallet/domain/withdrawal_summary.dart';
import 'package:ppv_app/features/wallet/presentation/widgets/wallet_card.dart';

class WithdrawalListItem extends StatelessWidget {
  final WithdrawalSummary withdrawal;

  const WithdrawalListItem({super.key, required this.withdrawal});

  Color _statusColor() => switch (withdrawal.status) {
        'pending'    => const Color(0xFFFFC107), // jaune
        'processing' => const Color(0xFF2196F3), // bleu
        'completed'  => AppColors.kSuccess,      // vert
        'rejected'   => AppColors.kError,        // rouge
        _            => AppColors.kTextSecondary,
      };

  String _statusLabel() => switch (withdrawal.status) {
        'pending'    => 'En attente',
        'processing' => 'En cours',
        'completed'  => 'Complété',
        'rejected'   => 'Rejeté',
        _            => withdrawal.status,
      };

  @override
  Widget build(BuildContext context) {
    final amountFcfa = withdrawal.amount ~/ 100;
    final d = withdrawal.createdAt;
    final dateStr = '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';

    return ListTile(
      key: Key('withdrawal-item-${withdrawal.id}'),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      title: Text(
        WalletCard.formatAmount(amountFcfa),
        style: const TextStyle(
          color: AppColors.kTextPrimary,
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),
      subtitle: Text(
        withdrawal.payoutMethodLabel ?? 'N/A',
        style: const TextStyle(color: AppColors.kTextSecondary, fontSize: 12),
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _statusColor().withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              _statusLabel(),
              style: TextStyle(
                color: _statusColor(),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateStr,
            style: const TextStyle(
              color: AppColors.kTextSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}
