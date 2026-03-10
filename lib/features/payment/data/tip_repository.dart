import 'package:dio/dio.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';

class TipRepository {
  final Dio _dio;
  TipRepository({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: AppConfig.baseUrl,
                connectTimeout: const Duration(
                    milliseconds: AppConfig.connectTimeoutMs),
                receiveTimeout: const Duration(
                    milliseconds: AppConfig.receiveTimeoutMs),
                headers: {'Accept': 'application/json'},
              ),
            );

  Future<Map<String, dynamic>> sendTip({
    required String slug,
    required int amountFcfa,
    required String email,
    String? phone,
  }) async {
    try {
      final body = <String, dynamic>{
        'slug': slug,
        'amount': amountFcfa * 100,
        'email': email,
      };
      if (phone != null) body['phone'] = phone;
      final response = await _dio.post('/payments/tip', data: body);
      return response.data['data'] as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
