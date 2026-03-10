import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/auto_withdrawal/data/auto_withdrawal_repository.dart';

class AutoWithdrawalProvider extends ChangeNotifier {
  final AutoWithdrawalRepository _repository;

  AutoWithdrawalProvider({AutoWithdrawalRepository? repository})
      : _repository = repository ?? AutoWithdrawalRepository();

  AutoWithdrawalRule? rule;
  bool isLoading = false;
  String? error;
  bool isSaving = false;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      rule = await _repository.getRule();
    } catch (e) {
      error = 'Impossible de charger la règle.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> save({
    required String triggerType,
    String? scheduleDay,
    int? thresholdFcfa,
    int? minFcfa,
  }) async {
    isSaving = true;
    error = null;
    notifyListeners();
    try {
      await _repository.upsertRule(
        triggerType: triggerType,
        scheduleDay: scheduleDay,
        thresholdAmountFcfa: thresholdFcfa,
        minWithdrawAmountFcfa: minFcfa,
      );
      await load();
    } catch (e) {
      error = 'Impossible de sauvegarder.';
    } finally {
      isSaving = false;
      notifyListeners();
    }
  }

  Future<void> disable() async {
    try {
      await _repository.deleteRule();
      await load();
    } catch (_) {}
  }
}
