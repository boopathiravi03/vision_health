enum RiskLevel {
  low,
  moderate,
  high,
}

class TriageResult {
  final RiskLevel riskLevel;
  final String title;
  final String action;
  final List<String> redFlags;
  final String reason;

  const TriageResult({
    required this.riskLevel,
    required this.title,
    required this.action,
    required this.redFlags,
    required this.reason,
  });

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'LOW RISK';

      case RiskLevel.moderate:
        return 'MODERATE RISK';

      case RiskLevel.high:
        return 'HIGH RISK';
    }
  }
}
