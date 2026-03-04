import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/referral/data/referral_repository.dart';
import 'package:ppv_app/features/referral/domain/referral_stats.dart';

class ReferralProvider extends ChangeNotifier {
  final ReferralRepository _repository;

  ReferralProvider({required ReferralRepository repository})
      : _repository = repository;

  bool _isLoading = false;
  String? _error;
  ReferralStats? _stats;
  bool _disposed = false;

  bool get isLoading => _isLoading;
  String? get error => _error;
  ReferralStats? get stats => _stats;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  Future<void> loadStats() async {
    _isLoading = true;
    _error = null;
    _safeNotify();

    try {
      _stats = await _repository.getStats();
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
    } finally {
      _isLoading = false;
      _safeNotify();
    }
  }
}
