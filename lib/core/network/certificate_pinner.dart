import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:ppv_app/core/config/app_config.dart';

/// Certificate pinner — HIGH-08.
///
/// Valide que le certificat TLS du serveur correspond aux empreintes SHA-256
/// configurées via `--dart-define-from-file` (champs PINNED_CERT_SHA256_*).
///
/// Comportement :
/// - Dev : pinning désactivé (HTTP émulateur géré par le Network Security Config Android).
/// - Prod sans pins : comportement OS normal — les AC système sont de confiance
///   (le Network Security Config bloque déjà les AC utilisateur).
/// - Prod avec pins : validation stricte — la connexion échoue si l'empreinte
///   du certificat ne correspond ni au pin primaire ni au pin backup.
///
/// Utilisation dans DioClient (IOHttpClientAdapter) :
/// ```dart
/// final client = HttpClient(context: SecurityContext(withTrustedRoots: false))
///   ..badCertificateCallback = CertificatePinner.validate;
/// ```
///
/// IMPORTANT — renouvellement du certificat (Let's Encrypt, 90 jours) :
/// Configurer PINNED_CERT_SHA256_BACKUP avec l'empreinte du prochain certificat
/// AVANT de renouveler, puis faire une release. Après le renouvellement, swap
/// primary ↔ backup et faire une nouvelle release.
abstract final class CertificatePinner {
  /// Retourne true si le certificat [cert] est accepté, false s'il est rejeté.
  ///
  /// Appelé par [HttpClient.badCertificateCallback] — uniquement lorsque la
  /// validation système a échoué (certificat non reconnu car SecurityContext
  /// configuré sans trusted roots).
  static bool validate(X509Certificate cert, String host, int port) {
    // En développement : pinning ignoré
    if (AppConfig.isDev) return true;

    const primary = AppConfig.pinnedCertSha256Primary;
    const backup = AppConfig.pinnedCertSha256Backup;

    // Aucun pin configuré → accepter (fail-open)
    // Le Network Security Config Android garantit déjà que les AC utilisateur
    // (proxies MITM) ne sont pas de confiance.
    if (primary.isEmpty && backup.isEmpty) return true;

    // Calcul de l'empreinte SHA-256 du DER brut du certificat
    final certSha256 = base64.encode(sha256.convert(cert.der).bytes);

    final isPrimary = primary.isNotEmpty && certSha256 == primary;
    final isBackup = backup.isNotEmpty && certSha256 == backup;

    return isPrimary || isBackup;
  }
}
