/// Entité d'acceptation CGU — aucune dépendance framework.
class TosAcceptance {
  final int id;
  final String acceptanceType;
  final String tosVersion;
  final DateTime acceptedAt;

  const TosAcceptance({
    required this.id,
    required this.acceptanceType,
    required this.tosVersion,
    required this.acceptedAt,
  });
}
