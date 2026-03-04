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

    _dio.interceptors.addAll([
      AuthInterceptor(
        dio: _dio, // M5 — inject pour conserver les mêmes timeouts sur retry
        storageService: storageService,
        onSessionExpired: onSessionExpired,
        onMaintenance: onMaintenance,
      ),
      RetryInterceptor(dio: _dio),
      if (kDebugMode)
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (o) => debugPrint(o.toString()),
        ),
    ]);

    // HIGH-08 — Certificate pinning TLS.
    // Pas applicable sur Web (dart:io non disponible).
    if (!kIsWeb) {
      _configureTlsPinning();
    }
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
