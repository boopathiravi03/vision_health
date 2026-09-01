import 'package:flutter/material.dart';

import '../../services/patient_service.dart';
import 'triage_result_screen.dart';

class PhcPatientScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> patient;

  const PhcPatientScreen({
    super.key,
    required this.patientId,
    this.patient = const {},
  });

  @override
  State<PhcPatientScreen> createState() =>
      _PhcPatientScreenState();
}

class _PhcPatientScreenState
    extends State<PhcPatientScreen> {
  final PatientService _patientService =
      PatientService();

  Map<String, dynamic>? patient;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    if (widget.patient.isEmpty) {
      loadPatient();
    } else {
      patient = widget.patient;
      loading = false;
    }
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
          title: const Text(
            'Patient Health Record',
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              'Unable to load patient record.\n\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    if (patient == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Patient Health Record',
          ),
        ),
        body: const Center(
          child: Text(
            'Patient record not found.',
          ),
        ),
      );
    }

    final name =
        patient!['name']?.toString() ??
            'Unknown';

    final age =
        patient!['age']?.toString() ??
            'N/A';

    final gender =
        patient!['gender']?.toString() ??
            'N/A';

    final village =
        patient!['village']?.toString() ??
            'N/A';

    final symptoms =
        patient!['symptoms']?.toString() ??
            'None recorded';

    final severity =
        patient!['severity']?.toString() ??
            'Not assessed';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patient Health Record',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Center(
              child: CircleAvatar(
                radius: 45,
                child: const Icon(
                  Icons.person,
                  size: 50,
                ),
              ),
            ),

            const SizedBox(height: 15),

            Center(
              child: Text(
                name,
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Center(
              child: Text(
                'Patient ID: ${widget.patientId}',
                style: const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ),

            const SizedBox(height: 30),

            _recordCard(
              'Age',
              age,
              Icons.cake,
            ),

            _recordCard(
              'Gender',
              gender,
              Icons.person_outline,
            ),

            _recordCard(
              'Village',
              village,
              Icons.location_on_outlined,
            ),

            _recordCard(
              'Symptoms',
              symptoms,
              Icons.sick_outlined,
            ),

            _recordCard(
              'Risk Level',
              severity,
              Icons.warning_amber_rounded,
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TriageResultScreen(
                        patientId: widget.patientId,
                        patient: patient!,
                      ),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.medical_services,
                ),
                label: const Text(
                  'START AI-ASSISTED TRIAGE',
                ),
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(
                    vertical: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recordCard(
    String title,
    String value,
    IconData icon,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 13,
            color: Colors.grey,
          ),
        ),
        subtitle: Padding(
          padding:
              const EdgeInsets.only(top: 4),
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
