import '../models/triage_result.dart';

class TriageEngine {
  static TriageResult assess({
    required int age,
    required List<String> symptoms,
    bool difficultyBreathing = false,
    bool unconscious = false,
    bool severeBleeding = false,
    bool chestPain = false,
    bool seizure = false,
    bool severeDehydration = false,
  }) {
    final normalizedSymptoms = symptoms
        .map((s) => s.toLowerCase().trim())
        .toList();

    final redFlags = <String>[];

    if (difficultyBreathing) {
      redFlags.add('Difficulty breathing');
    }

    if (unconscious) {
      redFlags.add('Loss of consciousness');
    }

    if (severeBleeding) {
      redFlags.add('Severe bleeding');
    }

    if (chestPain) {
      redFlags.add('Severe or concerning chest pain');
    }

    if (seizure) {
      redFlags.add('Seizure');
    }

    if (severeDehydration) {
      redFlags.add('Signs of severe dehydration');
    }

    if (redFlags.isNotEmpty) {
      return TriageResult(
        riskLevel: RiskLevel.high,
        title: 'Urgent attention required',
        action:
            'Refer the patient to the nearest appropriate healthcare facility immediately.',
        redFlags: redFlags,
        reason:
            'One or more warning signs were identified.',
      );
    }

    final concerningSymptoms = <String>[];

    if (_containsAny(
      normalizedSymptoms,
      [
        'high fever',
        'persistent vomiting',
        'severe weakness',
        'confusion',
      ],
    )) {
      concerningSymptoms.addAll(
        normalizedSymptoms.where(
          (s) =>
              s.contains('high fever') ||
              s.contains('persistent vomiting') ||
              s.contains('severe weakness') ||
              s.contains('confusion'),
        ),
      );
    }

    if (concerningSymptoms.isNotEmpty) {
      return TriageResult(
        riskLevel: RiskLevel.moderate,
        title: 'PHC assessment recommended',
        action:
            'Arrange a healthcare professional assessment at the nearest PHC.',
        redFlags: concerningSymptoms,
        reason:
            'The reported symptoms may require professional assessment.',
      );
    }

    if (age < 5 || age >= 65) {
      if (normalizedSymptoms.isNotEmpty) {
        return TriageResult(
          riskLevel: RiskLevel.moderate,
          title: 'PHC assessment recommended',
          action:
              'Consider evaluation at the nearest PHC, especially if symptoms persist or worsen.',
          redFlags: const [],
          reason:
              'Age and reported symptoms warrant additional caution.',
        );
      }
    }

    return TriageResult(
      riskLevel: RiskLevel.low,
      title: 'No immediate warning signs detected',
      action:
          'Monitor the patient and seek professional care if symptoms worsen, persist, or new warning signs appear.',
      redFlags: const [],
      reason:
          'No configured high-risk warning signs were detected.',
    );
  }

  static bool _containsAny(
    List<String> symptoms,
    List<String> terms,
  ) {
    for (final symptom in symptoms) {
      for (final term in terms) {
        if (symptom.contains(term)) {
          return true;
        }
      }
    }

    return false;
  }
}
