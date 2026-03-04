import 'package:dio/dio.dart';

class ReferralRemoteDatasource {
  final Dio _dio;

  ReferralRemoteDatasource({required Dio dio}) : _dio = dio;

  /// GET /api/v1/referral/my-code
  Future<Map<String, dynamic>> getMyCode() async {
    try {
      final response = await _dio.get('/referral/my-code');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// GET /api/v1/referral/stats
  Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _dio.get('/referral/stats');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }
}
