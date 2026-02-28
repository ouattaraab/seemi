import 'package:dio/dio.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';

/// Résultat d'initiation d'un paiement Paystack.
class PaymentInitiationResult {
  final String reference;
  final String authorizationUrl;

  const PaymentInitiationResult({
    required this.reference,
    required this.authorizationUrl,
  });

  factory PaymentInitiationResult.fromJson(Map<String, dynamic> json) {
    return PaymentInitiationResult(
      reference: json['reference'] as String,
      authorizationUrl: json['authorization_url'] as String,
    );
  }
}

/// Résultat de la vérification du statut de paiement.
class PaymentStatusResult {
  final bool isPaid;
  final String? originalUrl;
  /// Statut de la transaction : 'paid' | 'failed' | 'pending' | null
  final String? paymentStatus;

  const PaymentStatusResult({
    required this.isPaid,
    this.originalUrl,
    this.paymentStatus,
  });

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResult(
      isPaid: json['is_paid'] as bool? ?? false,
      originalUrl: json['original_url'] as String?,
      paymentStatus: json['payment_status'] as String?,
    );
  }
}

/// Repository paiement — appel public vers POST /api/v1/payments/initiate
/// et GET /api/v1/public/content/{slug}?ref={reference}.
///
/// Pas d'authentification requise (endpoints publics).
class PaymentRepository {
  final Dio _dio;

  PaymentRepository({Dio? dio})
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

  Future<PaymentInitiationResult> initiatePayment({
    required String slug,
    required String email,
    String? phone,
  }) async {
    try {
      final response = await _dio.post(
        '/payments/initiate',
        data: {
          'slug': slug,
          'email': email,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
        },
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PaymentInitiationResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromDioException(e);
      }
      throw NetworkException.fromDioException(e);
    }
  }

  /// Vérifie le statut de paiement via la référence Paystack.
  /// Retourne [PaymentStatusResult] avec is_paid et original_url.
  Future<PaymentStatusResult> checkPaymentStatus({
    required String slug,
    required String reference,
  }) async {
    try {
      final response = await _dio.get(
        '/public/content/$slug',
        queryParameters: {'ref': reference},
      );
      final data = response.data['data'] as Map<String, dynamic>;
      return PaymentStatusResult.fromJson(data);
    } on DioException catch (e) {
      if (e.response != null) {
        throw ApiException.fromDioException(e);
      }
      throw NetworkException.fromDioException(e);
    }
  }
}
