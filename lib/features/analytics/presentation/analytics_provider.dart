import 'package:flutter/foundation.dart';
import 'package:ppv_app/features/analytics/data/analytics_repository.dart';

class AnalyticsProvider extends ChangeNotifier {
  final AnalyticsRepository _repository;

  AnalyticsProvider({AnalyticsRepository? repository})
      : _repository = repository ?? AnalyticsRepository();

  AnalyticsData? data;
  int selectedPeriod = 30;
  bool isLoading = false;
  String? error;

  final List<int> periods = const [7, 30, 90];

  Future<void> load({int? period}) async {
    selectedPeriod = period ?? selectedPeriod;
    isLoading = true;
    error = null;
    notifyListeners();
    try {
      data = await _repository.getAnalytics(selectedPeriod);
    } catch (e) {
      error = 'Impossible de charger les analytics.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
