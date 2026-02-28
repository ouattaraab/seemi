import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/notifications/data/notification_repository.dart';
import 'package:ppv_app/features/notifications/domain/app_notification.dart';

class NotificationProvider extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationProvider({required NotificationRepository repository})
      : _repository = repository;

  // ─── State ───────────────────────────────────────────────────────────────

  List<AppNotification> _notifications = [];
  bool _isLoading = false;
  String? _error;
  String? _nextCursor;
  bool _hasMore = false;
  int _unreadCount = 0;

  List<AppNotification> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasMore => _hasMore;
  int get unreadCount => _unreadCount;

  // ─── Load / Pagination ───────────────────────────────────────────────────

  /// Charge (ou recharge) les notifications.
  /// [refresh] = true repart depuis le début (reset du curseur).
  Future<void> loadNotifications({bool refresh = false}) async {
    if (_isLoading) return;
    if (!refresh && !_hasMore && _notifications.isNotEmpty) return;

    if (refresh) {
      _notifications = [];
      _nextCursor = null;
      _hasMore = false;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getNotifications(cursor: _nextCursor);
      _notifications = refresh
          ? result.notifications
          : [..._notifications, ...result.notifications];
      _nextCursor  = result.nextCursor;
      _hasMore     = result.hasMore;
      _unreadCount = result.unreadCount;
    } on Exception catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charge la page suivante.
  Future<void> loadMore() async {
    if (!_hasMore) return;
    await loadNotifications();
  }

  // ─── Mark as read ────────────────────────────────────────────────────────

  /// Marque une notification comme lue — mise à jour optimiste immédiate,
  /// puis appel API en arrière-plan.
  Future<void> markAsRead(int id) async {
    final idx = _notifications.indexWhere((n) => n.id == id);
    if (idx == -1) return;

    final notification = _notifications[idx];
    if (notification.isRead) return; // déjà lue

    // Mise à jour optimiste
    _notifications = List.of(_notifications)
      ..[idx] = notification.copyWith(isRead: true, readAt: DateTime.now());
    _unreadCount = (_unreadCount - 1).clamp(0, _unreadCount);
    notifyListeners();

    try {
      await _repository.markAsRead(id);
    } on Exception {
      // Rollback en cas d'erreur réseau
      _notifications = List.of(_notifications)
        ..[idx] = notification;
      _unreadCount = _unreadCount + 1;
      notifyListeners();
    }
  }
}
