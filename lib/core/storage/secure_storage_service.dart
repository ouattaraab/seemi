import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Wrapper autour de FlutterSecureStorage pour les tokens JWT.
///
/// Fournit un accès typé aux tokens d'authentification.
/// Utilise flutter_secure_storage (Keychain iOS, EncryptedSharedPreferences Android).
class SecureStorageService {
  final FlutterSecureStorage _storage;

  static const _kAccessToken          = 'access_token';
  static const _kRefreshToken         = 'refresh_token';
  static const _kBiometricEnabled     = 'biometric_enabled';
  static const _kBiometricIdentifier  = 'biometric_identifier';
  static const _kBiometricPassword    = 'biometric_password';

  const SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: access),
      _storage.write(key: _kRefreshToken, value: refresh),
    ]);
  }

  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
    ]);
  }

  Future<bool> hasTokens() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  // ── Biométrie ──────────────────────────────────────────────────────────────

  Future<bool> isBiometricEnabled() async {
    final val = await _storage.read(key: _kBiometricEnabled);
    return val == 'true';
  }

  Future<void> saveBiometricCredentials({
    required String identifier,
    required String password,
  }) async {
    await Future.wait([
      _storage.write(key: _kBiometricEnabled,    value: 'true'),
      _storage.write(key: _kBiometricIdentifier, value: identifier),
      _storage.write(key: _kBiometricPassword,   value: password),
    ]);
  }

  Future<({String identifier, String password})?> getBiometricCredentials() async {
    final identifier = await _storage.read(key: _kBiometricIdentifier);
    final password   = await _storage.read(key: _kBiometricPassword);
    if (identifier == null || password == null) return null;
    return (identifier: identifier, password: password);
  }

  Future<void> clearBiometricCredentials() async {
    await Future.wait([
      _storage.delete(key: _kBiometricEnabled),
      _storage.delete(key: _kBiometricIdentifier),
      _storage.delete(key: _kBiometricPassword),
    ]);
  }
}
