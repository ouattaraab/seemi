import 'package:ppv_app/features/payout/domain/payout_method.dart';

/// Modèle moyen de reversement — mapping snake_case API → camelCase Dart.
class PayoutMethodModel extends PayoutMethod {
  const PayoutMethodModel({
    required super.id,
    required super.payoutType,
    super.provider,
    required super.accountNumberMasked,
    required super.accountHolderName,
    super.bankName,
    required super.isActive,
    super.updatedAt,
  });

  factory PayoutMethodModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final payoutType = json['payout_type'];
    final accountNumberMasked = json['account_number_masked'];
    final accountHolderName = json['account_holder_name'];
    final isActive = json['is_active'];

    if (id is! int ||
        payoutType is! String ||
        accountNumberMasked is! String ||
        accountHolderName is! String ||
        isActive is! bool) {
      throw const FormatException(
        'Invalid PayoutMethod JSON: missing or invalid fields',
      );
    }

    final updatedAtRaw = json['updated_at'];

    return PayoutMethodModel(
      id: id,
      payoutType: payoutType,
      provider: json['provider'] as String?,
      accountNumberMasked: accountNumberMasked,
      accountHolderName: accountHolderName,
      bankName: json['bank_name'] as String?,
      isActive: isActive,
      updatedAt: updatedAtRaw is String ? DateTime.tryParse(updatedAtRaw) : null,
    );
  }
}
