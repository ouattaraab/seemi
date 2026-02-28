import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';
import 'package:ppv_app/features/wallet/domain/wallet_transaction.dart';

class TransactionListItem extends StatelessWidget {
  final WalletTransaction transaction;

  const TransactionListItem({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final fcfa = transaction.amount ~/ 100;
    final formattedAmount = _formatFcfa(fcfa);
    final formattedDate = _formatDate(transaction.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.kPrimarySurface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Icon(Icons.arrow_downward, color: AppColors.kPrimary, size: 20),
      ),
      title: Text(
        transaction.buyerEmail ?? transaction.description ?? '—',
        style: const TextStyle(color: Colors.white, fontSize: 14),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '$formattedDate${transaction.paymentMethod != null ? ' · ${transaction.paymentMethod}' : ''}',
        style: const TextStyle(color: AppColors.kTextTertiary, fontSize: 12),
      ),
      trailing: Text(
        '+$formattedAmount FCFA',
        style: const TextStyle(
          color: AppColors.kPrimary,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  static String _formatFcfa(int fcfa) {
    final s = fcfa.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  static String _formatDate(DateTime dt) {
    final d = dt.toLocal();
    final day   = d.day.toString().padLeft(2, '0');
    final month = d.month.toString().padLeft(2, '0');
    final hour  = d.hour.toString().padLeft(2, '0');
    final min   = d.minute.toString().padLeft(2, '0');
    return '$day/$month/${d.year} $hour:$min';
  }
}
