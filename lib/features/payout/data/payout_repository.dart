import 'package:ppv_app/features/payout/data/payout_method_model.dart';
import 'package:ppv_app/features/payout/data/payout_remote_datasource.dart';

/// Repository moyen de reversement — délègue au datasource.
class PayoutRepository {
  final PayoutRemoteDataSource _dataSource;

  PayoutRepository({required PayoutRemoteDataSource dataSource})
      : _dataSource = dataSource;

  /// Configure ou met à jour le moyen de reversement.
  Future<PayoutMethodModel> configurePayoutMethod({
    required String payoutType,
    String? provider,
    required String accountNumber,
    required String accountHolderName,
    String? bankName,
  }) async {
    final response = await _dataSource.configurePayoutMethod(
      payoutType: payoutType,
      provider: provider,
      accountNumber: accountNumber,
      accountHolderName: accountHolderName,
      bankName: bankName,
    );

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }

    return PayoutMethodModel.fromJson(data);
  }

  /// Récupère le moyen de reversement existant, ou null si non configuré.
  Future<PayoutMethodModel?> getPayoutMethod() async {
    final response = await _dataSource.getPayoutMethod();
    if (response == null) return null;

    final data = response['data'];
    if (data is! Map<String, dynamic>) {
      throw Exception('Invalid API response: missing data field');
    }

    return PayoutMethodModel.fromJson(data);
  }
}
