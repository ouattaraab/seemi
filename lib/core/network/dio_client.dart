import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:ppv_app/core/network/auth_interceptor.dart';
import 'package:ppv_app/core/network/certificate_pinner.dart';
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
        dio: _dio, // M5 — inject pour conserver timeouts + cert pinning sur retry
        storageService: storageService,
        onSessionExpired: onSessionExpired,
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

  /// HIGH-08 — Configure le certificate pinning via IOHttpClientAdapter.
  ///
  /// - Si des pins sont configurés (PINNED_CERT_SHA256_PRIMARY non vide) :
  ///   toutes les connexions TLS passent par [CertificatePinner.validate].
  ///   Le SecurityContext est initialisé SANS trusted roots — ainsi, chaque
  ///   connexion déclenche badCertificateCallback qui vérifie l'empreinte.
  ///
  /// - Si aucun pin n'est configuré : comportement OS standard (AC système).
  ///   Le Network Security Config Android garantit déjà que les AC utilisateur
  ///   ne sont pas de confiance (protection MITM de base).
  ///
  /// - En dev : pas de SecurityContext personnalisé (HTTP émulateur autorisé).
  void _configureTlsPinning() {
    // Pins compilés via --dart-define-from-file : constantes à la compilation
    const hasPins = AppConfig.pinnedCertSha256Primary != '';

    (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      if (AppConfig.isDev || !hasPins) {
        // Dev ou prod sans pins → comportement OS normal
        return HttpClient();
      }

      // Prod avec pins : SecurityContext sans trusted roots pour forcer
      // le passage par badCertificateCallback sur TOUTES les connexions.
      return HttpClient(context: SecurityContext(withTrustedRoots: false))
        ..badCertificateCallback = CertificatePinner.validate;
    };
  }

  /// Accès au client Dio pour les repositories.
  Dio get dio => _dio;
}
