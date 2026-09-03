import 'package:flutter/material.dart';

import '../../models/patient.dart';
import '../../services/patient_service.dart';

class HealthRecordsScreen extends StatelessWidget {
  final String patientName;

  const HealthRecordsScreen({
    super.key,
    required this.patientName,
  });

  @override
  Widget build(BuildContext context) {
    final PatientService service = PatientService();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Health Records'),
      ),
      body: StreamBuilder<List<Patient>>(
        stream: service.getPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return _message(
              Icons.error_outline,
              'Unable to load health records.',
            );
          }

          final patients = snapshot.data ?? [];

          final records = patients.where((patient) {
            return patient.name.trim().toLowerCase() ==
                patientName.trim().toLowerCase();
          }).toList();

          if (records.isEmpty) {
            return _message(
              Icons.folder_open_outlined,
              'No health records found.',
              subtitle:
                  'Your ASHA worker has not added a record yet.',
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(records.length),
              const SizedBox(height: 18),

              const Text(
                'Your Records',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),

              ...records.map(
                (patient) => _recordCard(patient),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _summaryCard(int count) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.folder_shared_outlined,
              color: Color(0xFF087F73),
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Health History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count health record${count == 1 ? '' : 's'} available',
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordCard(Patient patient) {
    final risk = patient.riskLevel.toLowerCase();

    final Color riskColor = risk == 'urgent'
        ? Colors.red
        : risk == 'follow-up'
            ? Colors.orange
            : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0E9E6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.medical_information_outlined,
                color: Color(0xFF087F73),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Health Visit',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  patient.riskLevel.isEmpty
                      ? 'Recorded'
                      : patient.riskLevel,
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 24),

          _info(
            Icons.calendar_today_outlined,
            'Follow-up',
            patient.followUpDate.isEmpty
                ? 'Not specified'
                : patient.followUpDate,
          ),

          const SizedBox(height: 12),

          _info(
            Icons.medical_information_outlined,
            'Symptoms',
            patient.symptoms.isEmpty
                ? 'No symptoms recorded'
                : patient.symptoms,
          ),

          const SizedBox(height: 12),

          _info(
            Icons.health_and_safety_outlined,
            'Care recommendation',
            patient.aiRecommendation.isEmpty
                ? 'No recommendation recorded'
                : patient.aiRecommendation,
          ),

          const SizedBox(height: 12),

          _info(
            Icons.assignment_outlined,
            'Status',
            patient.status.isEmpty
                ? 'Not specified'
                : patient.status,
          ),
        ],
      ),
    );
  }

  Widget _info(
    IconData icon,
    String title,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF087F73),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _message(
    IconData icon,
    String title, {
    String? subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 58,
              color: const Color(0xFF087F73),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
