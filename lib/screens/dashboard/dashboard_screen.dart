import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../voice/voice_to_form_screen.dart';
import '../schemes/scheme_finder_screen.dart';
import '../patients/patient_list_screen.dart';
import '../vision/vision_screen.dart';
import '../followup/followup_screen.dart';
import '../../models/patient.dart';
import '../../services/patient_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final PatientService _patientService = PatientService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Vission Health',
          style: GoogleFonts.inter(
            color: const Color(0xFF073B36),
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF073B36),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good morning, ASHA Worker 👋',
                style: GoogleFonts.inter(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF073B36),
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Your village health center',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 22),

              _voiceAssistantCard(context),

              const SizedBox(height: 26),

              Text(
                "Today's Overview",
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF073B36),
                ),
              ),

              const SizedBox(height: 14),

              StreamBuilder<List<Patient>>(
                stream: _patientService.getPatients(),
                builder: (context, snapshot) {
                  final patients = snapshot.data ?? [];

                  final urgentCount = patients
                      .where((p) => p.riskLevel == 'Urgent')
                      .length;

                  final followUpCount = patients
                      .where((p) => p.riskLevel == 'Follow-up')
                      .length;

                  return Row(
                    children: [
                      Expanded(
                        child: _statCard(
                          Icons.people_outline_rounded,
                          'Patients',
                          '${patients.length}',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          Icons.warning_amber_rounded,
                          'Urgent',
                          '$urgentCount',
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statCard(
                          Icons.schedule,
                          'Follow-up',
                          '$followUpCount',
                        ),
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 26),

              Text(
                'Priority Patients',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF073B36),
                ),
              ),

              const SizedBox(height: 12),

              StreamBuilder<List<Patient>>(
                stream: _patientService.getPatients(),
                builder: (context, snapshot) {
                  final patients = snapshot.data ?? [];

                  final priorityPatients = patients
                      .where((p) =>
                          p.riskLevel == 'Urgent' ||
                          p.riskLevel == 'Follow-up')
                      .toList();

                  if (priorityPatients.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: const Color(0xFFE2EAE8),
                        ),
                      ),
                      child: Text(
                        'No priority patients right now.',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: priorityPatients
                        .map(
                          (patient) =>
                              _priorityCard(patient),
                        )
                        .toList(),
                  );
                },
              ),

              const SizedBox(height: 26),

              Text(
                'Follow-Up Queue',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF073B36),
                ),
              ),

              const SizedBox(height: 12),

              StreamBuilder<List<Patient>>(
                stream: _patientService.getPatients(),
                builder: (context, snapshot) {
                  final patients = snapshot.data ?? [];

                  final pendingFollowUps = patients
                      .where((p) =>
                          p.status != 'Completed' &&
                          p.followUpDate.isNotEmpty)
                      .length;

                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: const Color(0xFFE2EAE8),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5F5F2),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.calendar_month_outlined,
                            color: Color(0xFF087F73),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Pending Follow-ups',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$pendingFollowUps patient(s) scheduled',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    FollowUpScreen(),
                              ),
                            );
                          },
                          icon: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                          ),
                          label: const Text('View'),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 26),

              Card(
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(
                      Icons.account_balance,
                    ),
                  ),
                  title: const Text(
                    'Government Benefits',
                  ),
                  subtitle: const Text(
                    'Find potentially relevant health schemes',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            const SchemeFinderScreen(),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 26),

              Text(
                'Quick Actions',
                style: GoogleFonts.inter(
                  fontSize: 19,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF073B36),
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      context,
                      icon: Icons.camera_alt_outlined,
                      title: 'Visual\nScreening',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                VisionScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _actionCard(
                      context,
                      icon: Icons.account_balance_outlined,
                      title: 'Scheme\nFinder',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                const SchemeFinderScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _actionCard(
                      context,
                      icon: Icons.people_outline,
                      title: 'Patient\nRecords',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                PatientListScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _voiceAssistantCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF087F73),
            Color(0xFF075F58),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.mic_none_rounded,
            size: 38,
            color: Colors.white,
          ),

          const SizedBox(height: 14),

          Text(
            'Voice Health Assistant',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            'Speak naturally in Tamil or English',
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                     builder: (_) =>
                         const VoiceToFormScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor:
                    const Color(0xFF087F73),
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'START VOICE ASSISTANT',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2EAE8)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF087F73)),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityCard(Patient patient) {
    final isUrgent = patient.riskLevel == 'Urgent';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isUrgent
              ? Colors.red.shade200
              : Colors.orange.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isUrgent
                  ? Colors.red.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isUrgent
                  ? Icons.warning_amber_rounded
                  : Icons.schedule,
              color: isUrgent
                  ? Colors.red.shade700
                  : Colors.orange.shade700,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.name,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  patient.symptoms,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 10,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: isUrgent
                  ? Colors.red.shade50
                  : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              patient.riskLevel,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isUrgent
                    ? Colors.red.shade700
                    : Colors.orange.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        height: 125,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: const Color(0xFFE2EAE8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 30,
              color: const Color(0xFF087F73),
            ),
            const Spacer(),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: const Color(0xFF073B36),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
