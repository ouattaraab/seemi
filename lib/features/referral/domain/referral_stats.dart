/// Statistiques de parrainage d'un créateur.
class ReferralStats {
  final String code;
  final int usesCount;
  final int referralsCount;
  final int activeCount;
  final int totalEarned; // centimes FCFA

  const ReferralStats({
    required this.code,
    required this.usesCount,
    required this.referralsCount,
    required this.activeCount,
    required this.totalEarned,
  });
}
