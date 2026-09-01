class Patient {
  final String id;
  final String name;
  final int age;
  final String gender;
  final String village;
  final String phone;
  final String symptoms;
  final String status;
  final String followUpDate;
  final String riskLevel;
  final String aiRecommendation;

  Patient({
    required this.id,
    required this.name,
    required this.age,
    required this.gender,
    required this.village,
    required this.phone,
    required this.symptoms,
    required this.status,
    required this.followUpDate,
    required this.riskLevel,
    required this.aiRecommendation,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'gender': gender,
      'village': village,
      'phone': phone,
      'symptoms': symptoms,
      'status': status,
      'followUpDate': followUpDate,
      'riskLevel': riskLevel,
      'aiRecommendation': aiRecommendation,
    };
  }

  factory Patient.fromMap(
    String id,
    Map<dynamic, dynamic> map,
  ) {
    return Patient(
      id: id,
      name: map['name'] ?? '',
      age: int.tryParse(
            map['age'].toString(),
          ) ??
          0,
      gender: map['gender'] ?? '',
      village: map['village'] ?? '',
      phone: map['phone'] ?? '',
      symptoms: map['symptoms'] ?? '',
      status: map['status'] ?? 'Pending',
      followUpDate:
          map['followUpDate'] ?? '',
      riskLevel:
          map['riskLevel'] ?? 'Routine',
      aiRecommendation:
          map['aiRecommendation'] ?? '',
    );
  }
}
