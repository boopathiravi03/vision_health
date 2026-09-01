import 'package:flutter/material.dart';

import '../../models/patient.dart';
import '../schemes/scheme_finder_screen.dart';

class PatientDetailsScreen extends StatelessWidget {
  final Patient patient;

  const PatientDetailsScreen({
    super.key,
    required this.patient,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUrgent =
        patient.riskLevel.toLowerCase() ==
            'urgent';

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7FAF9),

      appBar: AppBar(
        title: const Text(
          'Patient Details',
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(18),

        child: Column(
          children: [
            _profileCard(),

            const SizedBox(height: 16),

            _riskCard(isUrgent),

            const SizedBox(height: 16),

            _infoCard(),

            const SizedBox(height: 16),

            _symptomsCard(),

            const SizedBox(height: 16),

            _recommendationCard(),

            const SizedBox(height: 20),

            _benefitsButton(context),
          ],
        ),
      ),
    );
  }

  Widget _profileCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),

      child: Column(
        children: [
          CircleAvatar(
            radius: 38,
            backgroundColor:
                const Color(0xFFE8F6F3),

            child: Text(
              patient.name.isNotEmpty
                  ? patient.name[0]
                      .toUpperCase()
                  : '?',

              style: const TextStyle(
                fontSize: 28,
                fontWeight:
                    FontWeight.bold,
                color:
                    Color(0xFF087F73),
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            patient.name,
            style: const TextStyle(
              fontSize: 24,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            '${patient.age} years • ${patient.gender}',
            style: const TextStyle(
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            patient.village,
            style: const TextStyle(
              color:
                  Color(0xFF087F73),
              fontWeight:
                  FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskCard(bool isUrgent) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: isUrgent
            ? Colors.red.withValues(alpha: .08)
            : Colors.orange
                .withValues(alpha: .08),

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: isUrgent
              ? Colors.red
              : Colors.orange,
        ),
      ),

      child: Row(
        children: [
          Icon(
            isUrgent
                ? Icons.warning_rounded
                : Icons.event_available,
            color: isUrgent
                ? Colors.red
                : Colors.orange,
            size: 32,
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  patient.riskLevel
                      .toUpperCase(),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        FontWeight.bold,
                    color: isUrgent
                        ? Colors.red
                        : Colors.orange,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  'Follow-up: ${patient.followUpDate}',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard() {
    return _sectionCard(
      title: 'Patient Information',
      icon: Icons.person_outline,

      child: Column(
        children: [
          _row(
            'Age',
            '${patient.age}',
          ),

          _row(
            'Gender',
            patient.gender,
          ),

          _row(
            'Village',
            patient.village,
          ),

          _row(
            'Phone',
            patient.phone.isEmpty
                ? 'Not provided'
                : patient.phone,
          ),

          _row(
            'Status',
            patient.status,
          ),
        ],
      ),
    );
  }

  Widget _symptomsCard() {
    return _sectionCard(
      title: 'Reported Symptoms',
      icon: Icons.medical_information_outlined,

      child: Text(
        patient.symptoms,
        style: const TextStyle(
          height: 1.5,
          fontSize: 15,
        ),
      ),
    );
  }

  Widget _recommendationCard() {
    return _sectionCard(
      title: 'AI-Assisted Recommendation',
      icon: Icons.auto_awesome,

      child: Text(
        patient.aiRecommendation,
        style: const TextStyle(
          height: 1.5,
        ),
      ),
    );
  }

  Widget _benefitsButton(
    BuildContext context,
  ) {
    return SizedBox(
      width: double.infinity,

      child: FilledButton.icon(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SchemeFinderScreen(
                age: patient.age,
                gender: patient.gender,
                situation: patient.symptoms,
              ),
            ),
          );
        },

        icon: const Icon(
          Icons.account_balance,
        ),

        label: const Text(
          'FIND HEALTH BENEFITS',
        ),

        style: FilledButton.styleFrom(
          padding:
              const EdgeInsets.symmetric(
            vertical: 15,
          ),
        ),
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
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
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
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight:
                      FontWeight.bold,
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

  Widget _row(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 11,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          SizedBox(
            width: 90,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
