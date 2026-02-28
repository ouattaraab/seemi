import 'package:flutter/material.dart';
import 'package:ppv_app/core/theme/app_colors.dart';

/// Carte affichant le solde du wallet en FCFA.
class WalletCard extends StatelessWidget {
  /// Solde en centimes FCFA.
  final int balanceCentimes;
  final bool isLoading;

  const WalletCard({
    super.key,
    required this.balanceCentimes,
    this.isLoading = false,
  });

  /// Formate un montant FCFA avec séparateur de milliers (espace).
  /// Ex : 2500 → "2 500 FCFA", 0 → "0 FCFA".
  static String formatAmount(int fcfa) {
    final s = fcfa.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(s[i]);
    }
    return '${buffer.toString()} FCFA';
  }

  @override
  Widget build(BuildContext context) {
    final fcfa = balanceCentimes ~/ 100;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
      decoration: BoxDecoration(
        color: AppColors.kBgSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black38, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Solde disponible',
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const SizedBox(
              height: 36,
              width: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.kPrimary,
              ),
            )
          else
            Text(
              formatAmount(fcfa),
              key: const Key('wallet-balance-text'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
        ],
      ),
    );
  }
}
