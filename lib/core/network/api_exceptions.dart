import 'package:dio/dio.dart';

/// Type d'erreur réseau.
enum NetworkExceptionType {
  timeout,
  noConnection,
  cancelled,
  unknown,
}

/// Exception réseau — pas de réponse du serveur.
class NetworkException implements Exception {
  final String message;
  final NetworkExceptionType type;

  const NetworkException({
    required this.message,
    required this.type,
  });

  /// Construit une [NetworkException] depuis un [DioException].
  factory NetworkException.fromDioException(DioException e) {
    final type = switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        NetworkExceptionType.timeout,
      DioExceptionType.connectionError => NetworkExceptionType.noConnection,
      DioExceptionType.cancel => NetworkExceptionType.cancelled,
      _ => NetworkExceptionType.unknown,
    };

    final message = switch (type) {
      NetworkExceptionType.timeout =>
        'La connexion a expiré. Vérifiez votre réseau et réessayez.',
      NetworkExceptionType.noConnection =>
        'Pas de connexion internet. Vérifiez votre réseau.',
      NetworkExceptionType.cancelled => 'Requête annulée.',
      NetworkExceptionType.unknown =>
        'Une erreur réseau inattendue est survenue.',
    };

    return NetworkException(message: message, type: type);
  }

  @override
  String toString() => 'NetworkException($type): $message';
}

/// Exception API — le serveur a répondu avec une erreur.
///
/// Parse le format de réponse standard PPV :
/// `{"success": false, "message": "...", "code": "ERROR_CODE", "errors": {...}}`
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? errorCode;
  final Map<String, dynamic>? errors;

  const ApiException({
    required this.message,
    this.statusCode,
    this.errorCode,
    this.errors,
  });

  /// Construit une [ApiException] depuis un [DioException] avec réponse.
  factory ApiException.fromDioException(DioException e) {
    final response = e.response;
    if (response == null) {
      return const ApiException(
        message: 'Erreur serveur sans réponse.',
        errorCode: 'NO_RESPONSE',
      );
    }

    final data = response.data;
    if (data is Map<String, dynamic>) {
      return ApiException(
        message: data['message'] as String? ?? 'Erreur inconnue',
        statusCode: response.statusCode,
        errorCode: data['code'] as String?,
        errors: data['errors'] as Map<String, dynamic>?,
      );
    }

    return ApiException(
      message: 'Erreur serveur (${response.statusCode})',
      statusCode: response.statusCode,
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isValidationError => statusCode == 422;
  bool get isRateLimited => statusCode == 429;
  bool get isServerError => statusCode != null && statusCode! >= 500;

  @override
  String toString() =>
      'ApiException($statusCode, $errorCode): $message';
}
