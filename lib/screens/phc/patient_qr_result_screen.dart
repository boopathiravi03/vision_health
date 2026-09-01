import 'package:flutter/material.dart';

import '../../services/patient_service.dart';

class PatientQrResultScreen extends StatefulWidget {
  final String patientId;

  const PatientQrResultScreen({
    super.key,
    required this.patientId,
  });

  @override
  State<PatientQrResultScreen> createState() =>
      _PatientQrResultScreenState();
}

class _PatientQrResultScreenState
    extends State<PatientQrResultScreen> {
  final PatientService _patientService =
      PatientService();

  Map<String, dynamic>? patient;

  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
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
        error = 'Unable to retrieve patient record.';
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5F9F8),

      appBar: AppBar(
        title: const Text(
          'Patient Health Summary',
        ),
      ),

      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : error != null
              ? _errorView()
              : patient == null
                  ? const Center(
                      child: Text(
                        'Patient record not found.',
                      ),
                    )
                  : _patientView(),
    );
  }

  Widget _patientView() {
    final data = patient!;

    final name =
        data['name']?.toString() ??
            'Unknown Patient';

    final age =
        data['age']?.toString() ??
            'Not available';

    final gender =
        data['gender']?.toString() ??
            'Not available';

    final village =
        data['village']?.toString() ??
            'Not available';

    final symptoms =
        data['symptoms']?.toString() ??
            'Not available';

    final risk =
        data['riskLevel']?.toString() ??
            'Not available';

    final recommendation =
        data['aiRecommendation']
                ?.toString() ??
            data['recommendation']
                ?.toString() ??
            'No recommendation available.';

    return SingleChildScrollView(
      padding:
          const EdgeInsets.all(16),

      child: Column(
        children: [
          _verifiedBanner(),

          const SizedBox(height: 14),

          _patientHeader(
            name,
            age,
            gender,
            village,
          ),

          const SizedBox(height: 14),

          _section(
            title: 'Risk Level',
            icon: Icons.warning_amber,
            child: Text(
              risk.toUpperCase(),
              style: TextStyle(
                fontSize: 20,
                fontWeight:
                    FontWeight.bold,
                color: _riskColor(risk),
              ),
            ),
          ),

          const SizedBox(height: 14),

          _section(
            title: 'Reported Symptoms',
            icon:
                Icons.medical_information,
            child: Text(
              symptoms,
              style: const TextStyle(
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 14),

          _section(
            title: 'AI Health Guidance',
            icon:
                Icons.health_and_safety,
            child: Text(
              recommendation,
              style: const TextStyle(
                height: 1.4,
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'This summary supports healthcare workflows and does not replace professional clinical assessment.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _verifiedBanner() {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color:
            const Color(0xFFE8F6F3),

        borderRadius:
            BorderRadius.circular(16),
      ),

      child: const Row(
        children: [
          Icon(
            Icons.verified_user,
            color:
                Color(0xFF087F73),
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Patient record retrieved from Vission Health',
              style: TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientHeader(
    String name,
    String age,
    String gender,
    String village,
  ) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Column(
        children: [
          const CircleAvatar(
            radius: 34,

            backgroundColor:
                Color(0xFFE8F6F3),

            child: Icon(
              Icons.person,
              size: 38,
              color:
                  Color(0xFF087F73),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            name,
            style: const TextStyle(
              fontSize: 23,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          Text(
            '$age years • $gender',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 5),

          Row(
            mainAxisAlignment:
                MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 17,
                color:
                    Color(0xFF087F73),
              ),

              const SizedBox(width: 4),

              Text(
                village,
                style:
                    const TextStyle(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _section({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(17),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              Icon(
                icon,
                color:
                    const Color(0xFF087F73),
              ),

              const SizedBox(width: 8),

              Text(
                title,
                style:
                    const TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }

  Color _riskColor(
    String risk,
  ) {
    final value =
        risk.toLowerCase();

    if (value.contains('high') ||
        value.contains('emergency') ||
        value.contains('critical')) {
      return Colors.red;
    }

    if (value.contains('medium')) {
      return Colors.orange;
    }

    return const Color(
      0xFF087F73,
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.error_outline,
              size: 60,
              color: Colors.red,
            ),

            const SizedBox(height: 12),

            Text(
              error!,
              textAlign:
                  TextAlign.center,
              style:
                  const TextStyle(
                fontSize: 17,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 18),

            FilledButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'SCAN AGAIN',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
