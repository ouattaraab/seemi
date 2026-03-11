/// Entité item d'un bundle — aucune dépendance framework.
class BundleItem {
  final int id;
  final String slug;
  final String blurUrl;
  final int priceFcfa;
  final String type; // photo, video

  const BundleItem({
    required this.id,
    required this.slug,
    required this.blurUrl,
    required this.priceFcfa,
    required this.type,
  });

  factory BundleItem.fromJson(Map<String, dynamic> json) {
    return BundleItem(
      id: json['id'] as int,
      slug: json['slug'] as String? ?? '',
      blurUrl: json['blur_url'] as String? ?? '',
      priceFcfa: json['price_fcfa'] as int? ?? 0,
      type: json['type'] as String? ?? 'photo',
    );
  }
}

/// Entité bundle — aucune dépendance framework.
class Bundle {
  final int id;
  final String title;
  final String? description;
  final String slug;
  final int totalPriceFcfa;
  final int discountedPriceFcfa;
  final int discountPercent;
  final int itemsCount;
  final String? createdAt;
  // For public view:
  final String? creatorName;
  final String? creatorUsername;
  final String? creatorAvatarUrl;
  final List<BundleItem> items;
  final bool isPaid;

  const Bundle({
    required this.id,
    required this.title,
    this.description,
    required this.slug,
    required this.totalPriceFcfa,
    required this.discountedPriceFcfa,
    required this.discountPercent,
    required this.itemsCount,
    this.createdAt,
    this.creatorName,
    this.creatorUsername,
    this.creatorAvatarUrl,
    this.items = const [],
    this.isPaid = false,
  });

  /// Construit depuis la réponse liste créateur ou création.
  factory Bundle.fromJson(Map<String, dynamic> json) {
    final creatorJson = json['creator'] as Map<String, dynamic>?;
    final rawItems = json['items'] as List<dynamic>?;

    return Bundle(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      slug: json['slug'] as String? ?? '',
      totalPriceFcfa: json['total_price_fcfa'] as int? ?? 0,
      discountedPriceFcfa: json['discounted_price_fcfa'] as int? ?? 0,
      discountPercent: json['discount_percent'] as int? ?? 0,
      itemsCount: json['items_count'] as int? ?? 0,
      createdAt: json['created_at'] as String?,
      creatorName: creatorJson?['name'] as String?,
      creatorUsername: creatorJson?['username'] as String?,
      creatorAvatarUrl: creatorJson?['avatar_url'] as String?,
      items: rawItems != null
          ? rawItems
              .cast<Map<String, dynamic>>()
              .map(BundleItem.fromJson)
              .toList()
          : const [],
      isPaid: json['is_paid'] as bool? ?? false,
    );
  }
}
