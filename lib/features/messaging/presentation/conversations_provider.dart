import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/messaging/data/messaging_repository.dart';
import 'package:ppv_app/features/messaging/domain/conversation.dart';

class ConversationsProvider extends ChangeNotifier {
  final MessagingRepository _repo;

  ConversationsProvider({MessagingRepository? repo})
      : _repo = repo ?? MessagingRepositoryImpl();

  List<Conversation> conversations = [];
  bool isLoading = false;
  String? error;

  Future<void> loadConversations() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      conversations = await _repo.getConversations();
    } catch (e) {
      error = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() => loadConversations();

  /// Start (or find) a conversation with a creator by ID.
  /// Returns the conversation on success, or throws on error.
  Future<Conversation> startConversation(int creatorId) async {
    final conv = await _repo.startConversation(creatorId);
    // Insert at top if not already present
    final idx = conversations.indexWhere((c) => c.id == conv.id);
    if (idx == -1) {
      conversations = [conv, ...conversations];
    }
    notifyListeners();
    return conv;
  }
}
