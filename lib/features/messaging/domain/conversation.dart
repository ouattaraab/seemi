/// Domain models for F14 — Exclusive Subscriber DMs.

// ─── Enums ────────────────────────────────────────────────────────────────────

enum MessageType {
  text,
  voice,
  lockedContent;

  static MessageType fromString(String value) {
    return switch (value) {
      'voice' => MessageType.voice,
      'locked_content' => MessageType.lockedContent,
      _ => MessageType.text,
    };
  }
}

// ─── Locked Content preview ───────────────────────────────────────────────────

class LockedContentPreview {
  final int id;
  final String? title;
  final String slug;
  final String? blurUrl;
  final int priceFcfa;

  const LockedContentPreview({
    required this.id,
    this.title,
    required this.slug,
    this.blurUrl,
    required this.priceFcfa,
  });

  factory LockedContentPreview.fromJson(Map<String, dynamic> j) {
    return LockedContentPreview(
      id: j['id'] as int,
      title: j['title'] as String?,
      slug: j['slug'] as String? ?? '',
      blurUrl: j['blur_url'] as String?,
      priceFcfa: j['price_fcfa'] as int? ?? 0,
    );
  }
}

// ─── Message ──────────────────────────────────────────────────────────────────

class Message {
  final int id;
  final int senderId;
  final MessageType type;
  final String? body;
  final String? voiceUrl;
  final LockedContentPreview? lockedContent;
  final bool isRead;
  final DateTime createdAt;

  const Message({
    required this.id,
    required this.senderId,
    required this.type,
    this.body,
    this.voiceUrl,
    this.lockedContent,
    required this.isRead,
    required this.createdAt,
  });

  factory Message.fromJson(Map<String, dynamic> j) {
    return Message(
      id: j['id'] as int,
      senderId: j['sender_id'] as int,
      type: MessageType.fromString(j['type'] as String? ?? 'text'),
      body: j['body'] as String?,
      voiceUrl: j['voice_url'] as String?,
      lockedContent: j['locked_content'] != null
          ? LockedContentPreview.fromJson(
              j['locked_content'] as Map<String, dynamic>)
          : null,
      isRead: j['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(j['created_at'] as String),
    );
  }
}

// ─── Other User ──────────────────────────────────────────────────────────────

class OtherUser {
  final int id;
  final String name;
  final String? username;
  final String? avatarUrl;

  const OtherUser({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
  });

  factory OtherUser.fromJson(Map<String, dynamic> j) {
    return OtherUser(
      id: j['id'] as int,
      name: j['name'] as String? ?? '',
      username: j['username'] as String?,
      avatarUrl: j['avatar_url'] as String?,
    );
  }
}

// ─── Conversation ─────────────────────────────────────────────────────────────

class Conversation {
  final int id;
  final OtherUser otherUser;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageAt;

  const Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    this.lastMessageAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> j) {
    return Conversation(
      id: j['id'] as int,
      otherUser: OtherUser.fromJson(j['other_user'] as Map<String, dynamic>),
      lastMessage: j['last_message'] as String?,
      unreadCount: j['unread_count'] as int? ?? 0,
      lastMessageAt: j['last_message_at'] != null
          ? DateTime.parse(j['last_message_at'] as String)
          : null,
    );
  }
}
