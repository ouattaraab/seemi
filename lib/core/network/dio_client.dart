import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/network/auth_interceptor.dart';
import 'package:ppv_app/core/network/retry_interceptor.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

/// Client HTTP PPV — Dio configuré avec interceptors.
///
/// Ordre des interceptors : Auth → Retry → Log.
/// Auth ajoute le Bearer token, Retry retente sur erreurs réseau,
/// Log trace en debug uniquement.
class DioClient {
  late final Dio _dio;

  DioClient({
    required SecureStorageService storageService,
    void Function()? onSessionExpired,
    void Function(Map<String, dynamic>)? onMaintenance,
  }) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout:
            const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        sendTimeout: const Duration(milliseconds: AppConfig.sendTimeoutMs),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    // HIGH-05 — TLS config doit être appliquée AVANT d'ajouter les interceptors
    // pour que _dio.httpClientAdapter soit déjà configuré quand on le passe à AuthInterceptor.
    if (!kIsWeb) {
      _configureTlsPinning();
    }

    _dio.interceptors.addAll([
      AuthInterceptor(
        dio: _dio, // M5 — inject pour conserver les mêmes timeouts sur retry
        storageService: storageService,
        onSessionExpired: onSessionExpired,
        onMaintenance: onMaintenance,
        // HIGH-05 — Partage l'adaptateur HTTP pour que le Dio de refresh
        // bénéficie de la même configuration TLS (crucial sur iOS).
        refreshHttpClientAdapter: _dio.httpClientAdapter,
      ),
      RetryInterceptor(dio: _dio),
      if (kDebugMode) _SanitizedLogInterceptor(),
    ]);

  }

  /// Configure le client TLS.
  ///
  /// La protection TLS repose sur deux couches complémentaires :
  ///   1. Android Network Security Config (network_security_config.xml) :
  ///      HTTPS uniquement + uniquement les AC système de confiance (bloque
  ///      les AC installées par l'utilisateur / proxies MITM).
  ///   2. Ce client utilise la validation OS standard (HttpClient() sans
  ///      SecurityContext personnalisé) pour éviter le bug connu de
  ///      BoringSSL/Android où SecurityContext(withTrustedRoots: false) ne
  ///      déclenche pas badCertificateCallback en release mode, causant un
  ///      échec silencieux de toutes les connexions HTTPS.
  ///
  /// En dev : HTTP vers l'émulateur autorisé (géré par le manifest debug).
  void _configureTlsPinning() {
    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      // Comportement OS standard dans tous les cas.
      // Le Network Security Config Android garantit la sécurité en production.
      return HttpClient();
    };
  }

  /// Accès au client Dio pour les repositories.
  Dio get dio => _dio;
}

/// Intercepteur de log qui masque les champs sensibles (password, token, email)
/// pour éviter l'exposition de PII dans les logs de debug.
class _SanitizedLogInterceptor extends Interceptor {
  static const _sensitiveKeys = {
    'password', 'password_confirmation', 'current_password',
    'new_password', 'new_password_confirmation',
    'token', 'access_token', 'refresh_token',
    'email', 'fcm_token',
  };

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('→ ${options.method} ${options.path}');
    if (options.data != null) {
      debugPrint('  body: ${_sanitize(options.data)}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint('← ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint('✗ ${err.response?.statusCode} ${err.requestOptions.path}: ${err.message}');
    handler.next(err);
  }

  dynamic _sanitize(dynamic data) {
    if (data is Map) {
      return {
        for (final entry in data.entries)
          entry.key: _sensitiveKeys.contains(entry.key.toString().toLowerCase())
              ? '***'
              : _sanitize(entry.value),
      };
    }
    if (data is List) return data.map(_sanitize).toList();
    return data;
  }
}
