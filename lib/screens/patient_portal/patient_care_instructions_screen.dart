import 'package:flutter/material.dart';
import '../../services/patient_service.dart';

class PatientCareInstructionsScreen extends StatefulWidget {
  final String patientId;

  const PatientCareInstructionsScreen({super.key, required this.patientId});

  @override
  State<PatientCareInstructionsScreen> createState() =>
      _PatientCareInstructionsScreenState();
}

class _PatientCareInstructionsScreenState
    extends State<PatientCareInstructionsScreen> {
  final PatientService _patientService = PatientService();

  Map<String, dynamic>? _patient;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final data = await _patientService.getPatient(widget.patientId);

      if (!mounted) return;

      setState(() {
        _patient = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(title: const Text('Care Instructions')),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Unable to load care instructions.\n\n$_error',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final patient = _patient;

    if (patient == null) {
      return const Center(child: Text('Patient record not found.'));
    }

    final aiRecommendation = patient['aiRecommendation']?.toString() ?? '';

    final followUpDate = patient['followUpDate']?.toString() ?? '';

    final riskLevel = patient['riskLevel']?.toString() ?? '';
    final redFlags = patient['redFlags'];
    final redFlagText = redFlags is List && redFlags.isNotEmpty
        ? redFlags.map((item) => item.toString()).join(', ')
        : '';

    final symptoms = patient['symptoms'];
    String symptomText = 'None recorded';
    if (symptoms is List && symptoms.isNotEmpty) {
      symptomText = symptoms.map((e) => e.toString()).join(', ');
    } else if (symptoms != null) {
      symptomText = symptoms.toString();
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionCard(
            title: 'Patient',
            icon: Icons.person_outline,
            child: Text(patient['name']?.toString() ?? '-'),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Current Symptoms',
            icon: Icons.medical_information_outlined,
            child: Text(symptomText),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: 'Care Instructions',
            icon: Icons.assignment_outlined,
            child: Text(
              aiRecommendation.isEmpty
                  ? 'No care instructions have been recorded yet.'
                  : aiRecommendation,
            ),
          ),
          const SizedBox(height: 16),
          if (riskLevel.isNotEmpty)
            _sectionCard(
              title: 'Risk Status',
              icon: Icons.health_and_safety_outlined,
              child: Text(riskLevel),
            ),
          if (riskLevel.isNotEmpty) const SizedBox(height: 16),
          if (redFlagText.isNotEmpty)
            _sectionCard(
              title: 'Important Warning Signs',
              icon: Icons.warning_amber_rounded,
              child: Text(
                '$redFlagText\n\nSeek urgent professional care if these signs are present or symptoms worsen.',
              ),
            ),
          if (redFlagText.isNotEmpty) const SizedBox(height: 16),
          if (followUpDate.isNotEmpty)
            _sectionCard(
              title: 'Follow-up Date',
              icon: Icons.event_available_outlined,
              child: Text(followUpDate),
            ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E9E6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF087F73)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}
