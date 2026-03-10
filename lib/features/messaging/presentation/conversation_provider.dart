import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/messaging/data/messaging_repository.dart';
import 'package:ppv_app/features/messaging/domain/conversation.dart';

class ConversationProvider extends ChangeNotifier {
  final int conversationId;
  final MessagingRepository _repo;

  ConversationProvider({
    required this.conversationId,
    MessagingRepository? repo,
  }) : _repo = repo ?? MessagingRepositoryImpl();

  List<Message> messages = [];
  bool isLoading = false;
  bool isSending = false;
  String? error;

  Timer? _pollTimer;

  // ─── Load ────────────────────────────────────────────────────────────────

  Future<void> loadMessages() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      messages = await _repo.getMessages(conversationId);
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── Polling ─────────────────────────────────────────────────────────────

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      pollMessages();
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> pollMessages() async {
    final afterId = messages.isNotEmpty ? messages.last.id : 0;
    try {
      final newMsgs = await _repo.getMessages(
        conversationId,
        afterId: afterId > 0 ? afterId : null,
      );
      if (newMsgs.isNotEmpty) {
        // De-duplicate: only add messages with id > last known
        final knownIds = messages.map((m) => m.id).toSet();
        final fresh = newMsgs.where((m) => !knownIds.contains(m.id)).toList();
        if (fresh.isNotEmpty) {
          messages = [...messages, ...fresh];
          notifyListeners();
        }
      }
    } catch (_) {
      // Silent fail — polling errors are non-fatal
    }
  }

  // ─── Send ────────────────────────────────────────────────────────────────

  Future<void> sendText(String body) async {
    if (body.trim().isEmpty) return;
    isSending = true;
    notifyListeners();
    try {
      final msg = await _repo.sendTextMessage(conversationId, body.trim());
      messages = [...messages, msg];
    } catch (e) {
      error = e.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendVoice(File file) async {
    isSending = true;
    notifyListeners();
    try {
      final msg = await _repo.sendVoiceMessage(conversationId, file);
      messages = [...messages, msg];
    } catch (e) {
      error = e.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> sendLockedContent(int contentId) async {
    isSending = true;
    notifyListeners();
    try {
      final msg = await _repo.sendLockedContent(conversationId, contentId);
      messages = [...messages, msg];
    } catch (e) {
      error = e.toString();
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
