class Referral {
  final String id;
  final String patientName;
  final int age;
  final String gender;
  final String riskLevel;
  final List<String> symptoms;
  final String reason;
  final String recommendedAction;
  final DateTime createdAt;
  final String status;

  Referral({
    required this.id,
    required this.patientName,
    required this.age,
    required this.gender,
    required this.riskLevel,
    required this.symptoms,
    required this.reason,
    required this.recommendedAction,
    required this.createdAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'referralId': id,
      'patientName': patientName,
      'age': age,
      'gender': gender,
      'riskLevel': riskLevel,
      'symptoms': symptoms,
      'reason': reason,
      'recommendedAction': recommendedAction,
      'createdAt': createdAt.toIso8601String(),
      'status': status,
    };
  }
}
