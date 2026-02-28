/// Configuration d'environnement PPV — compilée via `--dart-define-from-file`.
///
/// Usage : `flutter run --dart-define-from-file=env/dev.json`
/// Les valeurs par défaut correspondent à l'environnement de développement.
abstract final class AppConfig {
  // ─── Variables d'environnement ───
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/api/v1',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  // ─── Helpers d'environnement ───
  static bool get isDev => environment == 'dev';
  static bool get isProd => environment == 'prod';

  // ─── CGU / TOS ───
  static const String currentTosVersion = '1.0';

  // ─── Paystack (collecte paiements — Story 5.x) ───
  static const String paystackPublicKey = String.fromEnvironment(
    'PAYSTACK_PUBLIC_KEY',
    defaultValue: 'pk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx',
  );

  // ─── Certificate pinning TLS (HIGH-08) ───
  //
  // Empreintes SHA-256 (base64) du DER du certificat de production.
  // À configurer dans env/prod.json une fois le domaine prod obtenu.
  //
  // Commande pour obtenir la valeur primaire :
  //   openssl s_client -connect api.votredomaine.com:443 < /dev/null 2>/dev/null \
  //     | openssl x509 -outform der \
  //     | openssl dgst -sha256 -binary | base64
  //
  // Toujours définir un backup (prochain certificat Let's Encrypt) pour éviter
  // de bloquer les utilisateurs lors d'un renouvellement.
  //
  // Activation : ajouter dans env/prod.json :
  //   "PINNED_CERT_SHA256_PRIMARY": "base64_sha256_ici"
  //   "PINNED_CERT_SHA256_BACKUP":  "base64_sha256_backup_ici"
  static const String pinnedCertSha256Primary = String.fromEnvironment(
    'PINNED_CERT_SHA256_PRIMARY',
    defaultValue: '',
  );

  static const String pinnedCertSha256Backup = String.fromEnvironment(
    'PINNED_CERT_SHA256_BACKUP',
    defaultValue: '',
  );

  // ─── Timeouts réseau (millisecondes) ───
  static const int connectTimeoutMs = 15000;
  static const int receiveTimeoutMs = 15000;
  static const int sendTimeoutMs = 30000;
}
