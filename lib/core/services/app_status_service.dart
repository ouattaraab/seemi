import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ppv_app/core/config/app_config.dart';

/// Service de vérification du statut de l'application.
///
/// Utilise un Dio minimal (sans interceptors d'auth) pour éviter
/// les boucles avec l'AuthInterceptor.
/// Appelé en premier au démarrage (SplashScreen) avant toute action.
class AppStatusService {
  late final Dio _dio;

  AppStatusService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.baseUrl,
        connectTimeout: const Duration(milliseconds: AppConfig.connectTimeoutMs),
        receiveTimeout: const Duration(milliseconds: AppConfig.receiveTimeoutMs),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );

    if (!kIsWeb) {
      (_dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient =
          () => HttpClient();
    }
  }

  /// Vérifie le statut de l'app auprès du backend.
  ///
  /// Retourne la map JSON avec les clés `maintenance` et `update`.
  /// Lève une exception si le réseau est indisponible — l'appelant
  /// doit gérer l'erreur pour continuer normalement.
  Future<Map<String, dynamic>> check() async {
    final info = await PackageInfo.fromPlatform();
    final platform = Platform.isAndroid ? 'android' : 'ios';

    final response = await _dio.get(
      '/app/status',
      queryParameters: {
        'version': info.version,
        'platform': platform,
      },
    );

    return response.data as Map<String, dynamic>;
  }
}
