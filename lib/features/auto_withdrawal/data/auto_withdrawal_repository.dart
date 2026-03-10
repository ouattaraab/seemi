import 'package:dio/dio.dart';
import 'package:ppv_app/core/network/dio_client.dart';
import 'package:ppv_app/core/network/api_exceptions.dart';
import 'package:ppv_app/core/storage/secure_storage_service.dart';

class AutoWithdrawalRule {
  final String triggerType;
  final String? scheduleDay;
  final int? thresholdAmountFcfa;
  final int minWithdrawAmountFcfa;
  final bool isActive;
  final DateTime? lastTriggeredAt;

  const AutoWithdrawalRule({
    required this.triggerType,
    this.scheduleDay,
    this.thresholdAmountFcfa,
    required this.minWithdrawAmountFcfa,
    required this.isActive,
    this.lastTriggeredAt,
  });

  factory AutoWithdrawalRule.fromJson(Map<String, dynamic> j) => AutoWithdrawalRule(
        triggerType: j['trigger_type'] as String,
        scheduleDay: j['schedule_day'] as String?,
        thresholdAmountFcfa: j['threshold_amount_fcfa'] as int?,
        minWithdrawAmountFcfa: j['min_withdraw_amount_fcfa'] as int? ?? 5000,
        isActive: j['is_active'] as bool? ?? true,
        lastTriggeredAt: j['last_triggered_at'] != null
            ? DateTime.parse(j['last_triggered_at'] as String)
            : null,
      );
}

class AutoWithdrawalRepository {
  final DioClient _client;

  AutoWithdrawalRepository({DioClient? client})
      : _client = client ??
            DioClient(
              storageService: const SecureStorageService(),
            );

  Future<AutoWithdrawalRule?> getRule() async {
    try {
      final res = await _client.dio.get('/auto-withdrawal');
      final rule = res.data['data']['rule'];
      if (rule == null) return null;
      return AutoWithdrawalRule.fromJson(rule as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> upsertRule({
    required String triggerType,
    String? scheduleDay,
    int? thresholdAmountFcfa,
    int? minWithdrawAmountFcfa,
  }) async {
    try {
      await _client.dio.post('/auto-withdrawal', data: {
        'trigger_type': triggerType,
        if (scheduleDay != null) 'schedule_day': scheduleDay,
        if (thresholdAmountFcfa != null) 'threshold_amount_fcfa': thresholdAmountFcfa,
        if (minWithdrawAmountFcfa != null) 'min_withdraw_amount_fcfa': minWithdrawAmountFcfa,
      });
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }

  Future<void> deleteRule() async {
    try {
      await _client.dio.delete('/auto-withdrawal');
    } on DioException catch (e) {
      if (e.response != null) throw ApiException.fromDioException(e);
      throw NetworkException.fromDioException(e);
    }
  }
}
