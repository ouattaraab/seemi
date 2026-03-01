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
  StreamSubscription<String>? _tokenRefreshSubscription;

  /// Abonnement aux messages reçus en foreground (app ouverte).
  StreamSubscription<RemoteMessage>? _foregroundMessageSubscription;

  /// Abonnement aux taps sur notifications reçues en background.
  StreamSubscription<RemoteMessage>? _messageOpenedSubscription;

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

    // Active les notifications foreground sur iOS (badge + son + alerte).
    await _messaging.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    // HIGH-FCM : ne jamais logger le token FCM — il suffit à envoyer des notifications
    // arbitraires au device. Visible via `adb logcat` sur Android non chiffré.
    return token;
  }

  /// Écoute les renouvellements du token FCM.
  ///
  /// Annule l'abonnement précédent avant d'en créer un nouveau pour éviter
  /// l'accumulation de listeners sur les cycles login/logout.
  void listenTokenRefresh(void Function(String token) onTokenRefresh) {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen(onTokenRefresh);
  }

  /// Écoute les messages FCM reçus pendant que l'app est en **foreground**.
  ///
  /// [onMessage] est appelé avec le message dès réception.
  /// Annule l'abonnement précédent avant d'en créer un nouveau.
  void listenForegroundMessages(void Function(RemoteMessage) onMessage) {
    _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription =
        FirebaseMessaging.onMessage.listen(onMessage);
  }

  /// Écoute les taps utilisateur sur les notifications système reçues
  /// quand l'app était en **background** (mais pas terminated).
  ///
  /// [onOpened] est appelé avec le message associé à la notification tapée.
  void listenMessageOpenedApp(void Function(RemoteMessage) onOpened) {
    _messageOpenedSubscription?.cancel();
    _messageOpenedSubscription =
        FirebaseMessaging.onMessageOpenedApp.listen(onOpened);
  }

  /// Récupère le message qui a lancé l'app depuis l'état **terminated**.
  ///
  /// Retourne null si l'app n'a pas été ouverte via une notification.
  Future<RemoteMessage?> getInitialMessage() =>
      _messaging.getInitialMessage();

  /// Annule les abonnements foreground et onMessageOpenedApp.
  /// À appeler dans le [dispose] du widget qui a branché les listeners.
  void cancelMessageListeners() {
    _foregroundMessageSubscription?.cancel();
    _foregroundMessageSubscription = null;
    _messageOpenedSubscription?.cancel();
    _messageOpenedSubscription = null;
  }
}
