import 'package:dio/dio.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/core/network/dio_client.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';
import 'package:ppv_app/features/bundle/domain/bundle.dart';

/// Interface abstraite du repository bundles.
abstract class BundleRepository {
  Future<Bundle> createBundle({
    required String title,
    String? description,
    required List<int> contentIds,
    int discountPercent = 0,
  });

  Future<List<Bundle>> myBundles();

  Future<void> deleteBundle(int id);

  Future<Bundle> getPublicBundle(String slug, {String? ref});

  /// Retourne `{authorizationUrl, reference}`.
  Future<Map<String, String>> initiatePayment({
    required String bundleSlug,
    required String email,
  });

  Future<bool> verifyPayment(String reference);
}

/// Implémentation concrète.
///
/// - Endpoints authentifiés : DioClient (Bearer token via AuthInterceptor).
/// - Endpoints publics : Dio brut (pas d'intercepteur d'auth).
class BundleRepositoryImpl implements BundleRepository {
  final DioClient _client;
  final Dio _publicDio;

  BundleRepositoryImpl({DioClient? client, Dio? publicDio})
      : _client = client ??
            DioClient(storageService: const SecureStorageService()),
        _publicDio = publicDio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout:
                    const Duration(milliseconds: AppConfig.connectTimeoutMs),
                receiveTimeout:
                    const Duration(milliseconds: AppConfig.receiveTimeoutMs),
                headers: {'Accept': 'application/json'},
              ),
            );

  // ─── Authenticated ────────────────────────────────────────────────────────

  @override
  Future<Bundle> createBundle({
    required String title,
    String? description,
    required List<int> contentIds,
    int discountPercent = 0,
  }) async {
    try {
      final response = await _client.dio.post(
        '/bundles',
        data: {
          'title': title,
          if (description != null && description.isNotEmpty)
            'description': description,
          'content_ids': contentIds,
          'discount_percent': discountPercent,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Bundle.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<List<Bundle>> myBundles() async {
    try {
      final response = await _client.dio.get('/bundles/my');
      final data = response.data['data'] as List<dynamic>;
      return data
          .cast<Map<String, dynamic>>()
          .map(Bundle.fromJson)
          .toList();
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<void> deleteBundle(int id) async {
    try {
      await _client.dio.delete('/bundles/$id');
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  // ─── Public (no auth) ────────────────────────────────────────────────────

  @override
  Future<Bundle> getPublicBundle(String slug, {String? ref}) async {
    try {
      final response = await _publicDio.get(
        '/public/bundle/$slug',
        queryParameters: ref != null ? {'ref': ref} : null,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return Bundle.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<Map<String, String>> initiatePayment({
    required String bundleSlug,
    required String email,
  }) async {
    try {
      final response = await _publicDio.post(
        '/payments/initiate-bundle',
        data: {'bundle_slug': bundleSlug, 'email': email},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return {
        'authorizationUrl': data['authorization_url'] as String,
        'reference': data['reference'] as String,
      };
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  @override
  Future<bool> verifyPayment(String reference) async {
    try {
      final response = await _publicDio.post(
        '/payments/verify-bundle',
        data: {'reference': reference},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return (data['status'] as String?) == 'paid';
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
