import 'package:dio/dio.dart';
import 'package:ppv_app/core/network/dio_client.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

class AffiliateLink {
  final int id;
  final String code;
  final String shareUrl;
  final String? contentSlug;
  final int contentPriceFcfa;
  final int clicks;
  final int conversions;
  final double commissionRate;
  final DateTime createdAt;

  const AffiliateLink({
    required this.id,
    required this.code,
    required this.shareUrl,
    this.contentSlug,
    required this.contentPriceFcfa,
    required this.clicks,
    required this.conversions,
    required this.commissionRate,
    required this.createdAt,
  });

  factory AffiliateLink.fromJson(Map<String, dynamic> j) => AffiliateLink(
        id: j['id'] as int,
        code: j['code'] as String,
        shareUrl: j['share_url'] as String? ?? '',
        contentSlug: j['content_slug'] as String?,
        contentPriceFcfa: j['content_price_fcfa'] as int? ?? 0,
        clicks: j['clicks'] as int? ?? 0,
        conversions: j['conversions'] as int? ?? 0,
        commissionRate:
            (j['commission_rate'] as num?)?.toDouble() ?? 0.10,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}

class AffiliateRepository {
  final DioClient _client;

  AffiliateRepository({DioClient? client})
      : _client = client ??
            DioClient(
              storageService: const SecureStorageService(),
            );

  Future<Map<String, dynamic>> createLink(int contentId) async {
    try {
      final res = await _client.dio.post(
        '/affiliates/links',
        data: {'content_id': contentId},
      );
      return res.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<List<AffiliateLink>> myLinks() async {
    try {
      final res = await _client.dio.get('/affiliates/links');
      final list = res.data['data']['data'] as List<dynamic>? ?? [];
      return list
          .map((e) => AffiliateLink.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
