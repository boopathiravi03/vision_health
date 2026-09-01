import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/patient_service.dart';
import '../../services/triage_ai_service.dart';
import '../../services/triage_engine.dart';
import '../schemes/scheme_finder_screen.dart';
import '../triage/triage_result_screen.dart';

class HealthPassportScreen extends StatefulWidget {
  final String patientId;

  const HealthPassportScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<HealthPassportScreen> createState() =>
      _HealthPassportScreenState();
}

class _HealthPassportScreenState
    extends State<HealthPassportScreen> {
  final PatientService _patientService =
      PatientService();

  Map<String, dynamic>? patient;

  bool loading = true;
  String? error;

  bool triageLoading = false;
  String? triageError;

  @override
  void initState() {
    super.initState();
    loadPatient();
  }

  Future<void> loadPatient() async {
    try {
      final data =
          await _patientService.getPatient(
        widget.patientId,
      );

      if (!mounted) return;

      setState(() {
        patient = data;
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString();
        loading = false;
      });
    }
  }

  Future<void> runTriage() async {
    if (patient == null) {
      return;
    }

    setState(() {
      triageLoading = true;
      triageError = null;
    });

    try {
      final age = int.tryParse(
            patient!['age']?.toString() ?? '',
          ) ??
          0;

      final rawSymptoms =
          patient!['symptoms'];

      List<String> symptoms = [];

      if (rawSymptoms is List) {
        symptoms = rawSymptoms
            .map((e) => e.toString())
            .toList();
      } else if (rawSymptoms != null) {
        symptoms = [rawSymptoms.toString()];
      }

      final symptomText =
          symptoms.join(' ').toLowerCase();

      final assessment =
          TriageEngine.assess(
        age: age,
        symptoms: symptoms,
        difficultyBreathing:
            symptomText.contains('difficulty breathing') ||
                symptomText.contains('breathing difficulty'),
        unconscious:
            symptomText.contains('unconscious'),
        severeBleeding:
            symptomText.contains('severe bleeding'),
        chestPain:
            symptomText.contains('chest pain'),
        seizure:
            symptomText.contains('seizure'),
        severeDehydration:
            symptomText.contains('severe dehydration'),
      );

      final explanation =
          await TriageAiService.getExplanation(
        patientName:
            patient!['name']?.toString() ??
                'Patient',
        age: age,
        symptoms: symptoms,
        riskLevel: assessment.riskLabel,
        action: assessment.action,
        language: 'English',
      );

      if (!mounted) return;

      setState(() {
        triageLoading = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TriageResultScreen(
            patientName:
                patient!['name']?.toString() ??
                    'Patient',
            age: age,
            symptoms: symptoms,
            riskLevel: assessment.riskLabel,
            action: assessment.action,
            explanation:
                explanation['explanation']?.toString() ??
                    '',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        triageLoading = false;
        triageError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Health Passport'),
        ),
        body: const Center(
          child: Text(
            'Unable to load patient record.',
          ),
        ),
      );
    }

    if (patient == null) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Patient record not found.',
          ),
        ),
      );
    }

    return buildPassport();
  }

  Widget buildPassport() {
    final name =
        patient!['name']?.toString() ?? 'Unknown';

    final age =
        patient!['age']?.toString() ?? 'N/A';

    final gender =
        patient!['gender']?.toString() ?? 'N/A';

    final village =
        patient!['village']?.toString() ?? 'N/A';

    final severity =
        patient!['severity']?.toString() ??
            'Not assessed';

    final symptoms =
        patient!['symptoms'] is List
            ? (patient!['symptoms'] as List)
                .map((e) => e.toString())
                .join(', ')
            : 'None recorded';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Health Passport',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Center(
              child: Icon(
                Icons.health_and_safety,
                size: 80,
              ),
            ),

            const SizedBox(height: 20),

            Center(
              child: Text(
                'Vission Health',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(
                      fontWeight:
                          FontWeight.bold,
                    ),
              ),
            ),

            const SizedBox(height: 8),

            Center(
              child: Text(
                'Digital Health Passport',
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium,
              ),
            ),

            const SizedBox(height: 30),

            _infoCard(
              'Patient ID',
              widget.patientId,
            ),

            _infoCard(
              'Name',
              name,
            ),

            _infoCard(
              'Age',
              age,
            ),

            _infoCard(
              'Gender',
              gender,
            ),

            _infoCard(
              'Village',
              village,
            ),

            _infoCard(
              'Symptoms',
              symptoms,
            ),

            _infoCard(
              'Risk Level',
              severity,
            ),

            const SizedBox(height: 25),

            const Center(
              child: Text(
                'Scan this QR at the PHC',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 15),

            buildQr(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: triageLoading ? null : runTriage,
                icon: triageLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.medical_services,
                      ),
                label: Text(
                  triageLoading
                      ? 'RUNNING AI TRIAGE...'
                      : 'RUN AI TRIAGE',
                ),
              ),
            ),

            if (triageError != null) ...[
              const SizedBox(height: 12),

              Text(
                'Triage failed: $triageError',
                style: const TextStyle(
                  color: Colors.red,
                ),
              ),
            ],

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  final age = int.tryParse(
                        patient!['age']?.toString() ?? '',
                      ) ??
                      0;

                  final gender =
                      patient!['gender']?.toString() ?? '';

                  final symptoms =
                      patient!['symptoms'] is List
                          ? (patient!['symptoms'] as List)
                              .map((e) => e.toString())
                              .join(', ')
                          : '';

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          SchemeFinderScreen(
                        age: age,
                        gender: gender,
                        situation: symptoms,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.account_balance,
                ),
                label: const Text(
                  'FIND GOVERNMENT SCHEMES',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(
    String title,
    String value,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(
        bottom: 12,
      ),
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildQr() {
    return Center(
      child: QrImageView(
        data: widget.patientId,
        size: 220,
      ),
    );
  }
}
