import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Interceptor de retry — retente les requêtes GET/HEAD sur erreurs réseau.
///
/// Retry uniquement sur erreurs transitoires (timeout, connexion).
/// NE PAS retry sur erreurs business (400, 401, 403, 404, 422, 500).
/// NE PAS retry sur POST/PUT/DELETE (risque de double soumission).
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;
  final Duration initialDelay;

  /// Clé pour stocker le compteur de retry dans `requestOptions.extra`.
  static const _kRetryCount = 'retry_count';

  RetryInterceptor({
    required Dio dio,
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
  }) : _dio = dio;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (!shouldRetry(err)) {
      handler.next(err);
      return;
    }

    final retryCount = (err.requestOptions.extra[_kRetryCount] as int?) ?? 0;
    if (retryCount >= maxRetries) {
      handler.next(err);
      return;
    }

    final delay = initialDelay * (1 << retryCount); // Exponentiel : 1s, 2s, 4s
    if (kDebugMode) {
      // F-4 — Logger method + path uniquement (pas les query params qui peuvent
      // contenir des curseurs de pagination ou des identifiants sensibles)
      debugPrint(
        '[RetryInterceptor] Retry ${retryCount + 1}/$maxRetries '
        'après ${delay.inMilliseconds}ms — '
        '${err.requestOptions.method} ${err.requestOptions.path}',
      );
    }

    await Future<void>.delayed(delay);

    err.requestOptions.extra[_kRetryCount] = retryCount + 1;

    try {
      final response = await _dio.fetch(err.requestOptions);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  @visibleForTesting
  bool shouldRetry(DioException err) {
    // Uniquement les méthodes idempotentes
    final method = err.requestOptions.method.toUpperCase();
    if (method != 'GET' && method != 'HEAD') return false;

    // Uniquement les erreurs réseau transitoires
    return switch (err.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.connectionError =>
        true,
      _ => false,
    };
  }
}
