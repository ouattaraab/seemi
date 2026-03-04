import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_jailbreak_detection/flutter_jailbreak_detection.dart';

/// Détection de compromission du device (jailbreak iOS / root Android).
///
/// En mode debug, la vérification est ignorée pour ne pas bloquer
/// le développement sur des émulateurs ou devices de test.
abstract final class DeviceSecurity {
  /// Retourne true si le device est considéré compromis.
  ///
  /// Android : root détecté OU mode développeur activé.
  /// iOS : jailbreak détecté.
  /// Fail-open : si la détection lève une exception, on ne bloque pas.
  static Future<bool> isCompromised() async {
    if (kDebugMode) return false;
    if (!Platform.isAndroid && !Platform.isIOS) return false;

    try {
      final bool jailbroken = await FlutterJailbreakDetection.jailbroken;
      if (jailbroken) return true;

      if (Platform.isAndroid) {
        final bool devMode = await FlutterJailbreakDetection.developerMode;
        if (devMode) return true;
      }

      return false;
    } catch (_) {
      // Fail-open : ne pas bloquer si la détection échoue
      return false;
    }
  }
}
