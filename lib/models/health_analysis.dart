class HealthAnalysis {
  final String patientName;
  final int age;
  final String gender;
  final String language;
  final String transcript;
  final List<String> symptoms;
  final String duration;
  final String severity;
  final List<String> dangerSigns;
  final String riskLevel;
  final String recommendedAction;

  HealthAnalysis({
    required this.patientName,
    required this.age,
    required this.gender,
    required this.language,
    required this.transcript,
    required this.symptoms,
    required this.duration,
    required this.severity,
    required this.dangerSigns,
    required this.riskLevel,
    required this.recommendedAction,
  });

  Map<String, dynamic> toMap() {
    return {
      'patientName': patientName,
      'age': age,
      'gender': gender,
      'language': language,
      'transcript': transcript,
      'symptoms': symptoms,
      'duration': duration,
      'severity': severity,
      'dangerSigns': dangerSigns,
      'riskLevel': riskLevel,
      'recommendedAction': recommendedAction,
      'createdAt': DateTime.now().toIso8601String(),
    };
  }
}
