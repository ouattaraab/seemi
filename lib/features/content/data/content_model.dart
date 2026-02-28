import 'package:ppv_app/features/content/domain/content.dart';

/// Modèle contenu — mapping snake_case API → camelCase Dart.
class ContentModel extends Content {
  const ContentModel({
    required super.id,
    required super.type,
    required super.status,
    super.slug,
    super.shareUrl,
    super.price,
    super.blurUrl,
    required super.viewCount,
    required super.purchaseCount,
    super.createdAt,
  });

  factory ContentModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) {
      throw FormatException('Content id is not an int: $id');
    }

    final type = json['type'];
    if (type is! String) {
      throw FormatException('Content type is not a String: $type');
    }

    final status = json['status'];
    if (status is! String) {
      throw FormatException('Content status is not a String: $status');
    }

    return ContentModel(
      id: id,
      type: type,
      status: status,
      slug: json['slug'] as String?,
      shareUrl: json['share_url'] as String?,
      price: json['price'] as int?,
      blurUrl: json['blur_url'] as String?,
      viewCount: json['view_count'] as int? ?? 0,
      purchaseCount: json['purchase_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
