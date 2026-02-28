/// Entité moyen de reversement — aucune dépendance framework.
class PayoutMethod {
  final int id;
  final String payoutType;
  final String? provider;
  final String accountNumberMasked;
  final String accountHolderName;
  final String? bankName;
  final bool isActive;
  final DateTime? updatedAt;

  const PayoutMethod({
    required this.id,
    required this.payoutType,
    this.provider,
    required this.accountNumberMasked,
    required this.accountHolderName,
    this.bankName,
    required this.isActive,
    this.updatedAt,
  });
}
