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

  const PublicContentData({
    required this.id,
    required this.slug,
    required this.type,
    required this.blurPathUrl,
    required this.priceFcfa,
    required this.creatorName,
    required this.viewCount,
  });

  factory PublicContentData.fromJson(Map<String, dynamic> json) {
    return PublicContentData(
      id: json['id'] as int,
      slug: json['slug'] as String,
      type: json['type'] as String? ?? 'photo',
      blurPathUrl: json['blur_path_url'] as String?,
      priceFcfa: json['price_fcfa'] as int,
      creatorName: json['creator_name'] as String,
      viewCount: json['view_count'] as int,
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
}
