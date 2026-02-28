/// Modèle domaine d'une transaction wallet.
class WalletTransaction {
  final int id;
  final String type; // 'credit' | 'debit'
  final int amount; // centimes FCFA (montant NET)
  final int commissionAmount; // centimes FCFA prélevés
  final String? description;
  final String? buyerEmail;
  final String? paymentMethod;
  final DateTime createdAt;

  const WalletTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.commissionAmount,
    this.description,
    this.buyerEmail,
    this.paymentMethod,
    required this.createdAt,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      id:               json['id'] as int,
      type:             json['type'] as String,
      amount:           json['amount'] as int,
      commissionAmount: json['commission_amount'] as int? ?? 0,
      description:      json['description'] as String?,
      buyerEmail:       json['buyer_email'] as String?,
      paymentMethod:    json['payment_method'] as String?,
      createdAt:        DateTime.parse(json['created_at'] as String),
    );
  }
}
