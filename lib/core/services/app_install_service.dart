import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:ppv_app/core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _kInstallTracked = 'install_tracked';

/// Service de suivi du premier lancement.
///
/// Enregistre le premier lancement de l'application auprès du backend
/// une seule fois par appareil, en utilisant un UUID généré localement
/// comme `device_id`. Le flag est persisté dans SharedPreferences.
class AppInstallService {
  late final Dio _dio;

  AppInstallService() {
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

  /// Enregistre le premier lancement si ce n'est pas déjà fait.
  ///
  /// Silencieux en cas d'erreur réseau pour ne pas bloquer le démarrage.
  Future<void> trackIfFirstLaunch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kInstallTracked) == true) return;

      final info = await PackageInfo.fromPlatform();
      final platform = Platform.isAndroid ? 'android' : 'ios';
      final deviceId = await _getOrCreateDeviceId(prefs);

      await _dio.post(
        '/app/install',
        data: {
          'device_id': deviceId,
          'platform': platform,
          'version': info.version,
        },
      );

      await prefs.setBool(_kInstallTracked, true);
    } catch (_) {
      // Silencieux — ne bloque pas le démarrage
    }
  }

  /// Retourne ou génère un identifiant unique et persisté pour cet appareil.
  Future<String> _getOrCreateDeviceId(SharedPreferences prefs) async {
    const key = 'device_id';
    var id = prefs.getString(key);
    if (id == null || id.isEmpty) {
      id = _generateUuid();
      await prefs.setString(key, id);
    }
    return id;
  }

  /// UUID v4 cryptographiquement aléatoire (dart:math Random.secure).
  String _generateUuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // variant RFC 4122
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }
}
