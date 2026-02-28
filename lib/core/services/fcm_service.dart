import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';

/// Service FCM — récupère le token device et gère les permissions push.
///
/// L'envoi du token à l'API est délégué au caller (AuthProvider).
/// Ne bloque jamais le flux de connexion si FCM n'est pas disponible.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Abonnement courant au stream onTokenRefresh.
  /// Conservé pour annulation avant re-souscription (évite les listener leaks).
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Initialise les permissions FCM et retourne le token device.
  ///
  /// Retourne null si les permissions sont refusées ou si FCM n'est pas disponible.
  Future<String?> initialize() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      return null;
    }

    final token = await _messaging.getToken();
    // HIGH-FCM : ne jamais logger le token FCM — il suffit à envoyer des notifications
    // arbitraires au device. Visible via `adb logcat` sur Android non chiffré.
    return token;
  }

  /// Écoute les renouvellements du token FCM.
  ///
  /// Annule l'abonnement précédent avant d'en créer un nouveau pour éviter
  /// l'accumulation de listeners sur les cycles login/logout.
  /// [onTokenRefresh] est appelé avec le nouveau token dès qu'il change.
  void listenTokenRefresh(void Function(String token) onTokenRefresh) {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(onTokenRefresh);
  }
}
