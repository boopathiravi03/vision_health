import '../models/health_scheme.dart';

class SchemeService {
  static const List<HealthScheme> schemes = [
    HealthScheme(
      id: 'pmjay',
      name: 'Ayushman Bharat PM-JAY',
      description:
          'Health coverage support for eligible families.',
      eligibility:
          'Eligibility depends on the beneficiary database and applicable government criteria.',
      documents: [
        'Aadhaar or accepted ID',
        'Beneficiary identification details',
        'Other documents requested by the facility',
      ],
      steps: [
        'Check beneficiary eligibility',
        'Visit an empanelled health facility',
        'Carry the required identification documents',
        'Complete beneficiary verification',
      ],
      category: 'Health Coverage',
    ),

    HealthScheme(
      id: 'maternity',
      name: 'Maternity Support',
      description:
          'Government maternity-related support for eligible beneficiaries.',
      eligibility:
          'Eligibility depends on the applicable maternity programme and beneficiary criteria.',
      documents: [
        'Aadhaar or accepted ID',
        'Pregnancy-related records',
        'Bank details where applicable',
      ],
      steps: [
        'Visit the nearest government health facility',
        'Complete pregnancy registration',
        'Submit required documents',
        'Follow the facility instructions for benefit processing',
      ],
      category: 'Maternal Health',
    ),

    HealthScheme(
      id: 'immunization',
      name: 'Universal Immunization Programme',
      description:
          'Supports access to recommended childhood immunization services.',
      eligibility:
          'Children and eligible beneficiaries according to the applicable immunization schedule.',
      documents: [
        'Child health/immunization record',
        'Parent or guardian identification where required',
      ],
      steps: [
        'Check the child vaccination record',
        'Identify the next due vaccination',
        'Visit the nearest vaccination centre',
        'Update the vaccination record',
      ],
      category: 'Child Health',
    ),
  ];

  List<HealthScheme> findRelevantSchemes({
    required int age,
    required String gender,
    required String symptoms,
  }) {
    final results = <HealthScheme>[];

    final text = symptoms.toLowerCase();
    final normalizedGender = gender.toLowerCase();

    // General health coverage
    results.add(schemes.firstWhere(
      (scheme) => scheme.id == 'pmjay',
    ));

    // Maternal health
    if (normalizedGender == 'female' &&
        age >= 18 &&
        (text.contains('pregnant') ||
            text.contains('pregnancy') ||
            text.contains('maternity'))) {
      results.add(
        schemes.firstWhere(
          (scheme) => scheme.id == 'maternity',
        ),
      );
    }

    // Child health
    if (age < 6 &&
        (text.contains('vaccine') ||
            text.contains('vaccination') ||
            text.contains('immunization'))) {
      results.add(
        schemes.firstWhere(
          (scheme) => scheme.id == 'immunization',
        ),
      );
    }

    return results;
  }
}
