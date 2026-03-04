/// Entité contenu pure — aucune dépendance framework.
class Content {
  final int id;
  final String type;
  final String status;
  final String? slug;
  final String? shareUrl;
  final int? price;
  final String? blurUrl;
  final int viewCount;
  final int purchaseCount;
  final DateTime? createdAt;
  /// Vue unique — l'acheteur ne peut consulter ce contenu qu'une seule fois.
  final bool isViewOnce;

  const Content({
    required this.id,
    required this.type,
    required this.status,
    this.slug,
    this.shareUrl,
    this.price,
    this.blurUrl,
    required this.viewCount,
    required this.purchaseCount,
    this.createdAt,
    this.isViewOnce = false,
  });
}

/// Acheteur d'un contenu — visible uniquement par le créateur.
class ContentBuyer {
  final String? name;
  final String? email;
  final int amountFcfa;
  final DateTime paidAt;

  const ContentBuyer({
    this.name,
    this.email,
    required this.amountFcfa,
    required this.paidAt,
  });

  factory ContentBuyer.fromJson(Map<String, dynamic> json) {
    return ContentBuyer(
      name: json['buyer_name'] as String?,
      email: json['buyer_email'] as String?,
      amountFcfa: (json['amount_fcfa'] as int?) ?? 0,
      paidAt: DateTime.parse(json['paid_at'] as String),
    );
  }
}
