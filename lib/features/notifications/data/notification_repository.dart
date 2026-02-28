import 'package:dio/dio.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/features/notifications/domain/app_notification.dart';

/// Résultat paginé de GET /api/v1/notifications.
class NotificationsResult {
  final List<AppNotification> notifications;
  final String? nextCursor;
  final bool hasMore;
  final int unreadCount;

  const NotificationsResult({
    required this.notifications,
    required this.nextCursor,
    required this.hasMore,
    required this.unreadCount,
  });
}

/// Repository notifications — appels authentifiés.
/// Le [Dio] injecté doit déjà porter l'intercepteur JWT.
class NotificationRepository {
  final Dio _dio;

  NotificationRepository({required Dio dio}) : _dio = dio;

  /// GET /api/v1/notifications
  Future<NotificationsResult> getNotifications({String? cursor}) async {
    try {
      final response = await _dio.get(
        '/notifications',
        queryParameters: cursor != null ? {'cursor': cursor} : null,
      );
      final data = response.data['data'] as Map<String, dynamic>;
      final rawList = data['notifications'] as List;
      return NotificationsResult(
        notifications: rawList
            .cast<Map<String, dynamic>>()
            .map(AppNotification.fromJson)
            .toList(),
        nextCursor:  data['next_cursor'] as String?,
        hasMore:     data['has_more'] as bool? ?? false,
        unreadCount: data['unread_count'] as int? ?? 0,
      );
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  /// PUT /api/v1/notifications/{id}/read
  Future<void> markAsRead(int id) async {
    try {
      await _dio.put('/notifications/$id/read');
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
