import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/creator_profile/data/creator_profile_repository.dart';
import 'package:ppv_app/features/creator_profile/domain/creator_profile.dart';

class CreatorProfileProvider extends ChangeNotifier {
  final CreatorProfileRepository _repository;
  final String username;

  CreatorProfileProvider({required this.username, CreatorProfileRepository? repository})
      : _repository = repository ?? CreatorProfileRepository();

  CreatorProfile? profile;
  List<CreatorContentItem> contents = [];
  String? _nextCursor;
  bool hasMore = false;

  bool isLoadingProfile = false;
  bool isLoadingContents = false;
  bool isLoadingMore = false;
  String? profileError;
  String? contentsError;

  Future<void> loadProfile() async {
    isLoadingProfile = true;
    profileError = null;
    notifyListeners();
    try {
      profile = await _repository.getProfile(username);
    } catch (e) {
      profileError = 'Impossible de charger ce profil.';
    } finally {
      isLoadingProfile = false;
      notifyListeners();
    }
  }

  Future<void> loadContents({bool refresh = false}) async {
    if (refresh) {
      contents = [];
      _nextCursor = null;
      hasMore = false;
    }
    isLoadingContents = true;
    contentsError = null;
    notifyListeners();
    try {
      final result = await _repository.getContents(username);
      contents = result.items;
      _nextCursor = result.nextCursor;
      hasMore = result.hasMore;
    } catch (e) {
      contentsError = 'Impossible de charger les contenus.';
    } finally {
      isLoadingContents = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (isLoadingMore || !hasMore || _nextCursor == null) return;
    isLoadingMore = true;
    notifyListeners();
    try {
      final result = await _repository.getContents(username, cursor: _nextCursor);
      contents = [...contents, ...result.items];
      _nextCursor = result.nextCursor;
      hasMore = result.hasMore;
    } catch (_) {
      // silent fail for pagination
    } finally {
      isLoadingMore = false;
      notifyListeners();
    }
  }
}
