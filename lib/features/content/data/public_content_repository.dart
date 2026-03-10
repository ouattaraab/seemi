import 'package:dio/dio.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';

/// Modèle de données du contenu public (page acheteur via deep link).
class PublicContentData {
  final int id;
  final String slug;
  /// Type du contenu : 'photo' ou 'video'.
  final String type;
  final String? blurPathUrl;
  final int priceFcfa;
  final String creatorName;
  final int viewCount;
  final int purchaseCount;
  final bool isTrending;
  final int? creatorId;

  // ── F7 PWYW ──────────────────────────────────────────────────────────────
  final bool isPwyw;
  final int pwywMinimumPriceFcfa;

  // ── F8 Flash Sale ─────────────────────────────────────────────────────────
  final bool isFlashActive;
  final int originalPriceFcfa;
  final DateTime? flashEndsAt;

  const PublicContentData({
    required this.id,
    required this.slug,
    required this.type,
    required this.blurPathUrl,
    required this.priceFcfa,
    required this.creatorName,
    required this.viewCount,
    this.purchaseCount = 0,
    this.isTrending = false,
    this.creatorId,
    this.isPwyw = false,
    this.pwywMinimumPriceFcfa = 0,
    this.isFlashActive = false,
    int? originalPriceFcfa,
    this.flashEndsAt,
  }) : originalPriceFcfa = originalPriceFcfa ?? priceFcfa;

  factory PublicContentData.fromJson(Map<String, dynamic> json) {
    final priceFcfa = json['price_fcfa'] as int;
    return PublicContentData(
      id: json['id'] as int,
      slug: json['slug'] as String,
      type: json['type'] as String? ?? 'photo',
      blurPathUrl: json['blur_path_url'] as String?,
      priceFcfa: priceFcfa,
      creatorName: json['creator_name'] as String,
      viewCount: json['view_count'] as int,
      purchaseCount: json['purchase_count'] as int? ?? 0,
      isTrending: json['is_trending'] as bool? ?? false,
      creatorId: json['creator_id'] as int?,
      isPwyw: json['is_pwyw'] as bool? ?? false,
      pwywMinimumPriceFcfa: json['pwyw_minimum_price_fcfa'] as int? ?? priceFcfa,
      isFlashActive: json['is_flash_active'] as bool? ?? false,
      originalPriceFcfa: json['original_price_fcfa'] as int? ?? priceFcfa,
      flashEndsAt: json['flash_ends_at'] != null
          ? DateTime.parse(json['flash_ends_at'] as String)
          : null,
    );
  }
}

/// Repository public — appel sans authentification vers GET /api/v1/public/content/{slug}.
class PublicContentRepository {
  final Dio _dio;

  PublicContentRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout: const Duration(
                  milliseconds: AppConfig.connectTimeoutMs,
                ),
                receiveTimeout: const Duration(
                  milliseconds: AppConfig.receiveTimeoutMs,
                ),
                headers: {
                  'Accept': 'application/json',
                },
              ),
            );

  Future<PublicContentData> getPublicContent(String slug) async {
    try {
      final response = await _dio.get('/public/content/$slug');
      final data = response.data['data'] as Map<String, dynamic>;
      return PublicContentData.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        throw const ApiException(
          message: 'Contenu introuvable.',
          statusCode: 404,
          errorCode: 'NOT_FOUND',
        );
      }
      throw NetworkException.fromDioException(e);
    }
  }

  /// F13 — Récupère le média original (HLS ou R2 pre-signed URL).
  ///
  /// Retourne une map `{'type': 'hls'|'r2', 'url': '...'}`.
  ///
  /// L'URL passée en paramètre est l'URL signée HMAC retournée par
  /// `PublicContentController::show()` via le champ `original_url`.
  /// Elle peut être absolue (avec le domaine de base).
  Future<Map<String, String>> getOriginalMedia(String signedUrl) async {
    try {
      // L'URL signée est absolue — on utilise le Dio sans baseUrl pour ce call
      final response = await _dio.getUri(Uri.parse(signedUrl));
      final data = response.data['data'] as Map<String, dynamic>;
      return {
        'type': (data['type'] as String?) ?? 'r2',
        'url':  (data['url']  as String?) ?? '',
      };
    } on DioException catch (e) {
      if (e.response?.statusCode == 403 || e.response?.statusCode == 410) {
        throw ApiException(
          message: e.response?.statusCode == 410
              ? 'Ce contenu a déjà été visionné.'
              : 'Lien invalide ou expiré.',
          statusCode: e.response?.statusCode ?? 403,
          errorCode: e.response?.statusCode == 410 ? 'CONSUMED' : 'FORBIDDEN',
        );
      }
      throw NetworkException.fromDioException(e);
    }
  }
}
