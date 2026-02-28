import 'package:ppv_app/features/auth/domain/tos_acceptance.dart';

/// Modèle d'acceptation CGU — mapping snake_case API → camelCase Dart.
class TosAcceptanceModel extends TosAcceptance {
  const TosAcceptanceModel({
    required super.id,
    required super.acceptanceType,
    required super.tosVersion,
    required super.acceptedAt,
  });

  factory TosAcceptanceModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final acceptanceType = json['acceptance_type'];
    final tosVersion = json['tos_version'];
    final acceptedAt = json['accepted_at'];

    if (id is! int ||
        acceptanceType is! String ||
        tosVersion is! String ||
        acceptedAt is! String) {
      throw const FormatException(
        'Invalid TosAcceptance JSON: missing or invalid fields',
      );
    }

    return TosAcceptanceModel(
      id: id,
      acceptanceType: acceptanceType,
      tosVersion: tosVersion,
      acceptedAt: DateTime.parse(acceptedAt),
    );
  }
}
