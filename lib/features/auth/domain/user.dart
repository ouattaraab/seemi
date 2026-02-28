/// Entité utilisateur pure — aucune dépendance framework.
class User {
  final int id;
  final String phone;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String role;
  final String kycStatus;
  final DateTime? kycSubmittedAt;
  final DateTime? acceptedTosAt;
  final String? tosVersion;
  final bool isActive;
  final DateTime? createdAt;

  const User({
    required this.id,
    required this.phone,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    required this.role,
    required this.kycStatus,
    this.kycSubmittedAt,
    this.acceptedTosAt,
    this.tosVersion,
    required this.isActive,
    this.createdAt,
  });
}
