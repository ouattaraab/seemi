/// Profil public d'un créateur SeeMi.
class CreatorProfile {
  final int id;
  final String? username;
  final String name;
  final String? bio;
  final String? avatarUrl;
  final int contentCount;
  final int totalSales;
  final DateTime joinedAt;

  const CreatorProfile({
    required this.id,
    this.username,
    required this.name,
    this.bio,
    this.avatarUrl,
    required this.contentCount,
    required this.totalSales,
    required this.joinedAt,
  });

  factory CreatorProfile.fromJson(Map<String, dynamic> json) {
    return CreatorProfile(
      id: json['id'] as int,
      username: json['username'] as String?,
      name: json['name'] as String? ?? '',
      bio: json['bio'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      contentCount: json['content_count'] as int? ?? 0,
      totalSales: json['total_sales'] as int? ?? 0,
      joinedAt: DateTime.parse(json['joined_at'] as String),
    );
  }
}

/// Item de contenu d'un profil public.
class CreatorContentItem {
  final int id;
  final String type;
  final String? slug;
  final String? blurPathUrl;
  final int priceFcfa;
  final int purchaseCount;
  final bool isTrending;
  final DateTime createdAt;

  const CreatorContentItem({
    required this.id,
    required this.type,
    this.slug,
    this.blurPathUrl,
    required this.priceFcfa,
    required this.purchaseCount,
    required this.isTrending,
    required this.createdAt,
  });

  factory CreatorContentItem.fromJson(Map<String, dynamic> json) {
    return CreatorContentItem(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'photo',
      slug: json['slug'] as String?,
      blurPathUrl: json['blur_path_url'] as String?,
      priceFcfa: json['price_fcfa'] as int? ?? 0,
      purchaseCount: json['purchase_count'] as int? ?? 0,
      isTrending: json['is_trending'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}
