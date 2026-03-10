import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Service d'analytique mobile léger — envoie des événements UI vers POST /api/v1/events.
///
/// Design :
/// - Singleton initialisé une seule fois dans main.dart via [initialize].
/// - File d'attente en mémoire, vidée toutes les 5 s ou dès 10 événements.
/// - Envoi silencieux : aucune exception ne remonte à l'UI.
/// - Fonctionne pour les utilisateurs connectés et non connectés.
///
/// Événements standards :
///   content.viewed        — ouverture d'un écran de contenu
///   payment.tapped        — clic "Acheter"
///   payment.completed     — paiement confirmé côté serveur
///   content.shared        — partage d'un contenu
class MobileEventService {
  // ─── Singleton ────────────────────────────────────────────────────────────

  static MobileEventService? _instance;

  /// Initialise le service avec le client Dio de l'application.
  /// Doit être appelé une seule fois depuis main.dart, après la création de DioClient.
  static void initialize(Dio dio) {
    _instance = MobileEventService._(dio);
  }

  /// Accès global au service. Lance une AssertionError si [initialize] n'a pas été appelé.
  static MobileEventService get instance {
    assert(_instance != null, 'MobileEventService.initialize() must be called first.');
    return _instance!;
  }

  // ─── Implémentation ───────────────────────────────────────────────────────

  final Dio _dio;

  /// Identifiant de session généré au démarrage de l'app (regrouper les événements d'une visite).
  final String _sessionId =
      DateTime.now().millisecondsSinceEpoch.toString();

  final List<Map<String, dynamic>> _queue = [];
  Timer? _flushTimer;

  MobileEventService._(this._dio);

  /// Enregistre un événement dans la file d'attente.
  ///
  /// [type]    : identifiant de l'événement (ex: 'content.viewed').
  /// [payload] : données contextuelles libres (slug, content_id, reference…).
  void track(String type, {Map<String, dynamic>? payload}) {
    _queue.add({
      'type':       type,
      if (payload != null) 'payload': payload,
      'session_id': _sessionId,
      'timestamp':  DateTime.now().millisecondsSinceEpoch,
    });
    _scheduleFlush();
  }

  void _scheduleFlush() {
    if (_queue.length >= 10) {
      // Flush immédiat si la file est grande
      _flushTimer?.cancel();
      unawaited(flush());
    } else {
      _flushTimer?.cancel();
      _flushTimer = Timer(const Duration(seconds: 5), flush);
    }
  }

  /// Vide la file et envoie les événements au serveur.
  /// Peut être appelé manuellement (ex: avant fermeture de l'app).
  Future<void> flush() async {
    if (_queue.isEmpty) return;
    final batch = List<Map<String, dynamic>>.from(_queue);
    _queue.clear();
    _flushTimer?.cancel();
    try {
      await _dio.post('/events', data: {'events': batch});
    } catch (e) {
      // Silent fail — les analytics ne doivent jamais bloquer l'UX
      debugPrint('[MobileEventService] flush error: $e');
    }
  }
}
