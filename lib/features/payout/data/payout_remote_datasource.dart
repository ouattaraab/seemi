import 'package:dio/dio.dart';

/// Source de données distante pour les moyens de reversement.
class PayoutRemoteDataSource {
  final Dio _dio;

  PayoutRemoteDataSource({required Dio dio}) : _dio = dio;

  /// Configure ou met à jour le moyen de reversement.
  Future<Map<String, dynamic>> configurePayoutMethod({
    required String payoutType,
    String? provider,
    required String accountNumber,
    required String accountHolderName,
    String? bankName,
  }) async {
    try {
      final response = await _dio.put(
        '/profile/payout-method',
        data: {
          'payout_type': payoutType,
          // ignore: use_null_aware_elements
          if (provider != null) 'provider': provider,
          'account_number': accountNumber,
          'account_holder_name': accountHolderName,
          // ignore: use_null_aware_elements
          if (bankName != null) 'bank_name': bankName,
        },
      );
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }

  /// Récupère le moyen de reversement configuré. Retourne null si 404.
  Future<Map<String, dynamic>?> getPayoutMethod() async {
    try {
      final response = await _dio.get('/profile/payout-method');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return null;
      }
      final responseData = e.response?.data;
      final message = responseData is Map
          ? responseData['message'] as String? ?? 'Erreur serveur'
          : 'Erreur de connexion au serveur';
      throw Exception(message);
    }
  }
}
