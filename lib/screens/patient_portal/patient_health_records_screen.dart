import 'package:flutter/material.dart';

import '../../services/patient_service.dart';

class PatientHealthRecordsScreen extends StatefulWidget {
  final String patientId;

  const PatientHealthRecordsScreen({super.key, required this.patientId});

  @override
  State<PatientHealthRecordsScreen> createState() =>
      _PatientHealthRecordsScreenState();
}

class _PatientHealthRecordsScreenState
    extends State<PatientHealthRecordsScreen> {
  final PatientService _patientService = PatientService();

  bool loading = true;
  Map<String, dynamic>? patient;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final result = await _patientService.getPatient(widget.patientId);

      if (!mounted) return;

      setState(() {
        patient = result;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(title: const Text('Health Records')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? _errorView()
          : patient == null
          ? _notFound()
          : _recordView(),
    );
  }

  Widget _recordView() {
    final p = patient!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _patientHeader(p),

          const SizedBox(height: 20),

          const Text(
            'Patient Information',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _infoCard(Icons.person_outline, 'Name', p['name']),

          _infoCard(Icons.cake_outlined, 'Age', p['age']),

          _infoCard(Icons.wc_outlined, 'Gender', p['gender']),

          _infoCard(Icons.location_on_outlined, 'Village', p['village']),

          const SizedBox(height: 12),

          const Text(
            'Health Assessment',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          _infoCard(
            Icons.medical_information_outlined,
            'Symptoms',
            p['symptoms'],
          ),

          _infoCard(Icons.warning_amber_rounded, 'Risk Level', p['riskLevel']),

          _infoCard(Icons.assignment_outlined, 'Status', p['status']),

          _infoCard(Icons.event_outlined, 'Follow-up Date', p['followUpDate']),

          const SizedBox(height: 12),

          const Text(
            'AI / ASHA Recommendation',
            style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 12),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F6F3),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFD3ECE7)),
            ),
            child: Text(
              p['aiRecommendation']?.toString().isNotEmpty == true
                  ? p['aiRecommendation'].toString()
                  : 'No recommendation recorded.',
              style: const TextStyle(fontSize: 15, height: 1.5),
            ),
          ),

          const SizedBox(height: 20),

          _warningCard(),
        ],
      ),
    );
  }

  Widget _patientHeader(Map<String, dynamic> p) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF087F73),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            child: Icon(Icons.person, size: 38, color: Color(0xFF087F73)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['name']?.toString() ?? 'Patient',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Health ID: ${widget.patientId}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(IconData icon, String title, dynamic value) {
    final text = value is List
        ? value.map((item) => item.toString()).join(', ')
        : value?.toString().trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE0E9E6)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF087F73)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  text?.isNotEmpty == true ? text! : 'Not recorded',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _warningCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'These records are provided for information. '
              'Follow the instructions of your ASHA worker, PHC staff or doctor.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            const SizedBox(height: 12),
            const Text(
              'Unable to load health records.',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                setState(() {
                  loading = true;
                  error = null;
                });
                _loadPatient();
              },
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _notFound() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Patient record was not found.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17),
        ),
      ),
    );
  }
}
