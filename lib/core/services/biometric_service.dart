import 'package:local_auth/local_auth.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

/// Service d'authentification biométrique (empreinte digitale / Face ID).
///
/// Stocke les credentials chiffrés dans FlutterSecureStorage
/// (Keychain iOS, EncryptedSharedPreferences Android).
class BiometricService {
  static final _auth = LocalAuthentication();

  /// Vérifie si l'appareil supporte la biométrie.
  static Future<bool> isAvailable() async {
    try {
      final canCheck  = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return canCheck && supported;
    } catch (_) {
      return false;
    }
  }

  /// Déclenche la vérification biométrique avec un motif localisé.
  static Future<bool> authenticate({
    String reason = 'Confirmez votre identité pour accéder à SeeMi',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  /// Vérifie si la connexion biométrique est activée.
  static Future<bool> isEnabled() =>
      const SecureStorageService().isBiometricEnabled();

  /// Active la connexion biométrique en sauvegardant les credentials.
  static Future<void> enable(String identifier, String password) =>
      const SecureStorageService().saveBiometricCredentials(
        identifier: identifier,
        password: password,
      );

  /// Désactive la connexion biométrique et efface les credentials.
  static Future<void> disable() =>
      const SecureStorageService().clearBiometricCredentials();

  /// Retourne les credentials stockés (null si aucun ou biométrie désactivée).
  static Future<({String identifier, String password})?> getCredentials() =>
      const SecureStorageService().getBiometricCredentials();
}
