/// Résumé d'une demande de retrait pour l'affichage dans le portefeuille créateur.
class WithdrawalSummary {
  final int id;
  final int amount; // centimes FCFA
  final String status; // 'pending' | 'processing' | 'completed' | 'rejected'
  final DateTime createdAt;
  final String? payoutMethodLabel; // ex: "Orange Mobile Money — ****1234"

  const WithdrawalSummary({
    required this.id,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.payoutMethodLabel,
  });

  factory WithdrawalSummary.fromJson(Map<String, dynamic> json) {
    String? label;
    final pm = json['payout_method'] as Map<String, dynamic>?;
    if (pm != null) {
      final type = pm['payout_type'] == 'mobile_money'
          ? 'Mobile Money'
          : 'Compte bancaire';
      final provider = pm['provider'] as String?;
      final masked = pm['account_number_masked'] as String? ?? '';
      label = provider != null
          ? '${_capitalize(provider)} $type — $masked'
          : '$type — $masked';
    }

    return WithdrawalSummary(
      id: json['id'] as int,
      amount: json['amount'] as int,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      payoutMethodLabel: label,
    );
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
