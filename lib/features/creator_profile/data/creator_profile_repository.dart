import 'package:dio/dio.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/features/creator_profile/domain/creator_profile.dart';

class CreatorProfileRepository {
  final Dio _dio;

  CreatorProfileRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
                receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
                headers: {'Accept': 'application/json'},
              ),
            );

  Future<CreatorProfile> getProfile(String username) async {
    try {
      final response = await _dio.get('/creators/$username');
      final data = response.data['data'] as Map<String, dynamic>;
      return CreatorProfile.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<({List<CreatorContentItem> items, String? nextCursor, bool hasMore})>
      getContents(String username, {String? cursor}) async {
    try {
      final response = await _dio.get(
        '/creators/$username/contents',
        queryParameters: {if (cursor != null) 'cursor': cursor},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final items = (data['data'] as List<dynamic>)
          .map((e) => CreatorContentItem.fromJson(e as Map<String, dynamic>))
          .toList();
      return (
        items: items,
        nextCursor: data['next_cursor'] as String?,
        hasMore: data['has_more'] as bool? ?? false,
      );
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
