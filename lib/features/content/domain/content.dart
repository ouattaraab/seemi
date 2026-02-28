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
  });
}
