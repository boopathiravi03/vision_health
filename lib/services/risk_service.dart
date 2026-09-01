class RiskAssessment {
  final String level;
  final String recommendation;

  RiskAssessment({
    required this.level,
    required this.recommendation,
  });
}

class RiskService {
  RiskAssessment assess({
    required int age,
    required String gender,
    required String symptoms,
  }) {
    final text = symptoms.toLowerCase();

    final urgentKeywords = [
      'difficulty breathing',
      'breathing problem',
      'chest pain',
      'unconscious',
      'severe bleeding',
      'heavy bleeding',
      'seizure',
      'stroke',
      'severe chest pain',
      'cannot breathe',
      'fainted',
    ];

    for (final keyword in urgentKeywords) {
      if (text.contains(keyword)) {
        return RiskAssessment(
          level: 'Urgent',
          recommendation:
              'Immediate professional medical evaluation is recommended. Contact the nearest health facility or emergency service.',
        );
      }
    }

    final followUpKeywords = [
      'fever',
      'vomiting',
      'weakness',
      'persistent pain',
      'infection',
      'wound',
      'cough',
      'diarrhea',
    ];

    for (final keyword in followUpKeywords) {
      if (text.contains(keyword)) {
        return RiskAssessment(
          level: 'Follow-up',
          recommendation:
              'ASHA worker should monitor the patient and arrange a health-facility evaluation if symptoms persist or worsen.',
        );
      }
    }

    return RiskAssessment(
      level: 'Routine',
      recommendation:
          'Continue routine monitoring and provide appropriate health guidance.',
    );
  }
}
