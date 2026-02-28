# Seeme

Application mobile **Seeme** — plateforme de monétisation de contenu exclusif pour créateurs africains.
Les créateurs publient des photos ou vidéos floues ; les acheteurs paient pour les débloquer.

## Stack technique

| Composant | Technologie |
|-----------|-------------|
| Framework | Flutter 3 |
| Gestion d'état | Provider + ChangeNotifier |
| HTTP | Dio (interceptors JWT + retry) |
| Auth | Firebase Auth (OTP SMS) |
| Notifications push | Firebase Cloud Messaging |
| Stockage sécurisé | flutter_secure_storage |
| Paiement | WebView Paystack + polling statut |
| Téléchargement | package `gal` (galerie système) |
| Tests | flutter_test — 453 tests |

## Fonctionnalités

- **Auth** — Connexion/inscription par OTP SMS (Firebase), refresh JWT automatique
- **KYC** — Formulaire de soumission de justificatif d'identité
- **CGU** — Acceptation des conditions générales
- **Profil** — Avatar, bio, informations créateur
- **Contenu** — Upload photo/vidéo, tarification, lien de partage
- **Paiement** — WebView Paystack, polling du statut, révélation du contenu débloqué
- **Téléchargement** — Sauvegarde dans la galerie (photo ou vidéo)
- **Wallet** — Solde, historique des transactions (infinite scroll), retrait
- **Moyens de paiement** — Ajout/suppression de comptes Mobile Money et bancaires
- **Notifications** — Centre in-app avec pagination curseur, marquage lu optimiste

## Prérequis

- Flutter 3.x (`flutter --version`)
- Fichier `google-services.json` (Android) et `GoogleService-Info.plist` (iOS) — fournis par Firebase
- API `seemi-api` accessible

## Installation

```bash
git clone https://github.com/ouattaraab/seemi.git
cd seemi

flutter pub get
```

Copier et renseigner le fichier de configuration :

```bash
cp env/dev.json.example env/dev.json
```

```json
{
  "BASE_URL": "http://10.0.2.2:8000/api/v1",
  "PINNED_CERT_SHA256_PRIMARY": ""
}
```

Placer les fichiers Firebase :
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`

```bash
flutter run --dart-define-from-file=env/dev.json
```

## Tests

```bash
flutter test
```

## Build de production

```bash
# Android
flutter build apk --dart-define-from-file=env/prod.json --release

# iOS
flutter build ipa --dart-define-from-file=env/prod.json --release
```

## Sécurité

- Certificat pinning SHA-256 (activé via `PINNED_CERT_SHA256_PRIMARY` dans `env/prod.json`)
- Android Network Security Config — cleartext bloqué hors émulateur
- `FLAG_SECURE` Android — captures d'écran et app switcher bloqués
- Masquage UI iOS en arrière-plan (protection sélecteur d'apps)
- Tokens JWT stockés dans `flutter_secure_storage` (Keychain iOS / Keystore Android)
- Aucun log de token en production

## Licence

Propriétaire — © 2026 Aboubakar Ouattara
