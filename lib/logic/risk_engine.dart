class RiskResult {
  final String level;
  final String action;
  final List<String> dangerSigns;

  RiskResult({
    required this.level,
    required this.action,
    required this.dangerSigns,
  });
}

class RiskEngine {
  static RiskResult assess({
    required List<String> symptoms,
    required String severity,
    required String duration,
  }) {
    final normalized = symptoms
        .map((e) => e.toLowerCase().trim())
        .toList();

    final dangerSigns = <String>[];

    final emergencyPatterns = {
      'breathing difficulty':
          'Difficulty breathing',
      'shortness of breath':
          'Shortness of breath',
      'chest pain':
          'Chest pain',
      'unconscious':
          'Unconsciousness',
      'seizure':
          'Seizure',
      'severe bleeding':
          'Severe bleeding',
      'fainting':
          'Fainting',
      'blue lips':
          'Blue lips',
    };

    for (final entry in emergencyPatterns.entries) {
      if (normalized.any(
        (symptom) => symptom.contains(entry.key),
      )) {
        if (!dangerSigns.contains(entry.value)) {
          dangerSigns.add(entry.value);
        }
      }
    }

    if (dangerSigns.isNotEmpty ||
        severity.toLowerCase() == 'severe') {
      return RiskResult(
        level: 'URGENT',
        action:
            'Immediate medical evaluation is recommended. Contact the appropriate emergency or healthcare service.',
        dangerSigns: dangerSigns,
      );
    }

    if (severity.toLowerCase() == 'moderate' ||
        normalized.length >= 3 ||
        _hasPersistentDuration(duration)) {
      return RiskResult(
        level: 'MEDIUM',
        action:
            'Arrange evaluation at the nearest appropriate healthcare facility and continue monitoring.',
        dangerSigns: [],
      );
    }

    return RiskResult(
      level: 'LOW',
      action:
          'Continue monitoring and seek healthcare assistance if symptoms worsen or persist.',
      dangerSigns: [],
    );
  }

  static bool _hasPersistentDuration(String duration) {
    final match = RegExp(
      r'(\d+)',
    ).firstMatch(duration);

    if (match == null) return false;

    final days = int.tryParse(match.group(1)!) ?? 0;

    return days >= 3;
  }
}
