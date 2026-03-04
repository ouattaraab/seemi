import 'package:dio/dio.dart';
import 'package:ppv_app/features/referral/data/referral_remote_datasource.dart';
import 'package:ppv_app/features/referral/domain/referral_stats.dart';

class ReferralRepository {
  final ReferralRemoteDatasource _datasource;

  ReferralRepository({required Dio dio})
      : _datasource = ReferralRemoteDatasource(dio: dio);

  Future<ReferralStats> getStats() async {
    final codeData  = await _datasource.getMyCode();
    final statsData = await _datasource.getStats();

    final codePayload  = codeData['data']  as Map<String, dynamic>;
    final statsPayload = statsData['data'] as Map<String, dynamic>;

    return ReferralStats(
      code:           codePayload['code'] as String,
      usesCount:      codePayload['uses_count'] as int,
      referralsCount: statsPayload['referrals_count'] as int,
      activeCount:    statsPayload['active_count'] as int,
      totalEarned:    statsPayload['total_earned'] as int,
    );
  }
}
