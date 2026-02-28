/// Entité domaine d'une notification in-app.
/// Nommée [AppNotification] pour éviter le conflit avec dart:ui.
class AppNotification {
  final int id;
  final String type;
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    required this.isRead,
    this.readAt,
    required this.createdAt,
  });

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id:        json['id'] as int,
      type:      json['type'] as String,
      title:     json['title'] as String,
      body:      json['body'] as String,
      data:      json['data'] as Map<String, dynamic>?,
      isRead:    json['is_read'] as bool? ?? false,
      readAt:    json['read_at'] != null
                     ? DateTime.parse(json['read_at'] as String)
                     : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// Retourne une copie avec [isRead] et [readAt] mis à jour.
  /// Utilisé pour la mise à jour optimiste dans le provider.
  AppNotification copyWith({bool? isRead, DateTime? readAt}) {
    return AppNotification(
      id:        id,
      type:      type,
      title:     title,
      body:      body,
      data:      data,
      isRead:    isRead ?? this.isRead,
      readAt:    readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}
