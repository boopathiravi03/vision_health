import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../services/patient_service.dart';

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
