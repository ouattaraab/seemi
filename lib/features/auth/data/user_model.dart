import 'package:ppv_app/features/auth/domain/user.dart';

/// Modèle utilisateur — mapping snake_case API → camelCase Dart.
class UserModel extends User {
  const UserModel({
    required super.id,
    super.email,
    required super.phone,
    super.firstName,
    super.lastName,
    super.avatarUrl,
    required super.role,
    required super.kycStatus,
    super.kycSubmittedAt,
    super.acceptedTosAt,
    super.tosVersion,
    required super.isActive,
    super.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String?,
      phone: json['phone'] as String? ?? '',
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      role: json['role'] as String,
      kycStatus: json['kyc_status'] as String,
      kycSubmittedAt: json['kyc_submitted_at'] != null
          ? DateTime.parse(json['kyc_submitted_at'] as String)
          : null,
      acceptedTosAt: json['accepted_tos_at'] != null
          ? DateTime.parse(json['accepted_tos_at'] as String)
          : null,
      tosVersion: json['tos_version'] as String?,
      isActive: json['is_active'] as bool,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }
}
