import 'package:flutter/material.dart';

import '../../models/patient.dart';
import '../../services/connectivity_service.dart';
import '../../services/patient_service.dart';
import '../patients/patient_details_screen.dart';
import '../voice/voice_to_form_screen.dart';

class AshaDashboard extends StatefulWidget {
  const AshaDashboard({super.key});

  @override
  State<AshaDashboard> createState() => _AshaDashboardState();
}

class _AshaDashboardState extends State<AshaDashboard> {
  final PatientService _patientService =
      PatientService();

  final ConnectivityService
      _connectivityService =
      ConnectivityService();

  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _checkConnectivity();
    _connectivityService.connectionStream.listen((online) {
      if (mounted) {
        setState(() {
          _isOnline = online;
        });
      }
    });
  }

  Future<void> _checkConnectivity() async {
    final online = await _connectivityService.hasInternet();
    if (mounted) {
      setState(() {
        _isOnline = online;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),

      appBar: AppBar(
        title: const Text(
          'Vission Health',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.notifications_outlined,
            ),
          ),
        ],
      ),

      body: StreamBuilder<List<Patient>>(
        stream: _patientService.getPatients(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Unable to load patients\n${snapshot.error}',
                textAlign: TextAlign.center,
              ),
            );
          }

          final patients =
              snapshot.data ?? [];

          final total =
              patients.length;

          final urgent =
              patients.where(
            (p) => p.riskLevel
                .toLowerCase() ==
                'urgent',
          ).length;

          final followUp =
              patients.where(
            (p) => p.riskLevel
                .toLowerCase() ==
                'follow-up',
          ).length;

          return RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(
                const Duration(
                  milliseconds: 500,
                ),
              );
            },

            child: ListView(
              padding:
                  const EdgeInsets.all(18),

              children: [
                if (!_isOnline)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    color: Colors.orange.withValues(alpha: .12),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.cloud_off,
                          size: 20,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Offline mode — patient records will sync automatically when internet returns.',
                            style: TextStyle(
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                _welcomeSection(),

                const SizedBox(height: 20),

                _stats(
                  total: total,
                  followUp: followUp,
                  urgent: urgent,
                ),

                const SizedBox(height: 26),

                _sectionTitle(
                  'Quick Actions',
                ),

                const SizedBox(height: 12),

                _quickActions(context),

                const SizedBox(height: 26),

                _sectionTitle(
                  'Needs Attention',
                ),

                const SizedBox(height: 12),

                _attentionList(
                  context,
                  patients,
                ),

                const SizedBox(height: 26),

                _sectionTitle(
                  'Recent Patients',
                ),

                const SizedBox(height: 12),

                _recentPatients(
                  context,
                  patients,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _welcomeSection() {
    return Container(
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color:
            const Color(0xFFE8F6F3),
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: const Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Text(
            'Good morning 👋',
            style: TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),

          SizedBox(height: 4),

          Text(
            'ASHA Worker',
            style: TextStyle(
              fontSize: 25,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF087F73),
            ),
          ),

          SizedBox(height: 8),

          Text(
            'Manage patients, follow-ups and health services from one place.',
            style: TextStyle(
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stats({
    required int total,
    required int followUp,
    required int urgent,
  }) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            icon: Icons.people,
            value: total.toString(),
            label: 'Patients',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: Icons.event,
            value: followUp.toString(),
            label: 'Follow-up',
          ),
        ),

        const SizedBox(width: 10),

        Expanded(
          child: _statCard(
            icon: Icons.warning_amber,
            value: urgent.toString(),
            label: 'Urgent',
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF087F73),
          ),

          const SizedBox(height: 8),

          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 2),

          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _quickActions(
    BuildContext context,
  ) {
    return Row(
      children: [
        Expanded(
          child: _actionCard(
            context,
            Icons.mic,
            'Voice-to-Form',
            () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const VoiceToFormScreen(),
                ),
              );
            },
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: _actionCard(
            context,
            Icons.person_add,
            'Add Patient',
            () {
              // Connect to Add Patient screen.
            },
          ),
        ),
      ],
    );
  }

  Widget _actionCard(
    BuildContext context,
    IconData icon,
    String title,
    VoidCallback onTap,
  ) {
    return InkWell(
      borderRadius:
          BorderRadius.circular(16),

      onTap: onTap,

      child: Container(
        padding:
            const EdgeInsets.all(18),

        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(16),
          border: Border.all(
            color:
                const Color(0xFFE0E9E6),
          ),
        ),

        child: Column(
          children: [
            Icon(
              icon,
              size: 30,
              color:
                  const Color(0xFF087F73),
            ),

            const SizedBox(height: 8),

            Text(
              title,
              textAlign:
                  TextAlign.center,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _attentionList(
    BuildContext context,
    List<Patient> patients,
  ) {
    final attention =
        patients.where(
      (patient) =>
          patient.riskLevel
              .toLowerCase() ==
              'urgent' ||
          patient.riskLevel
              .toLowerCase() ==
              'follow-up',
    ).toList();

    if (attention.isEmpty) {
      return _emptyCard(
        'No patients currently need attention.',
      );
    }

    final items = attention.take(5).toList();

    return Column(
      children: List.generate(
        items.length,
        (index) {
          final patient = items[index];
          return _attentionCard(
            context,
            patient,
          );
        },
      ),
    );
  }

  Widget _attentionCard(
    BuildContext context,
    Patient patient,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PatientDetailsScreen(
              patient: patient,
            ),
          ),
        );
      },
      child: _patientCard(
        patient,
        showRisk: true,
      ),
    );
  }

  Widget _recentPatients(
    BuildContext context,
    List<Patient> patients,
  ) {
    if (patients.isEmpty) {
      return _emptyCard(
        'No patient records yet.',
      );
    }

    final items = patients.take(5).toList();

    return Column(
      children: List.generate(
        items.length,
        (index) {
          final patient = items[index];
          return _recentCard(
            context,
            patient,
          );
        },
      ),
    );
  }

  Widget _recentCard(
    BuildContext context,
    Patient patient,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PatientDetailsScreen(
              patient: patient,
            ),
          ),
        );
      },
      child: _patientCard(
        patient,
      ),
    );
  }

  Widget _patientCard(
    Patient patient, {
    bool showRisk = false,
  }) {
    final isUrgent =
        patient.riskLevel
            .toLowerCase() ==
            'urgent';

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 10,
      ),

      padding:
          const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(15),
        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),

      child: Row(
        children: [
          CircleAvatar(
            backgroundColor:
                const Color(0xFFE8F6F3),

            child: Text(
              patient.name.isNotEmpty
                  ? patient.name[0]
                      .toUpperCase()
                  : '?',

              style:
                  const TextStyle(
                color:
                    Color(0xFF087F73),
                fontWeight:
                    FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  patient.name,
                  style:
                      const TextStyle(
                    fontWeight:
                        FontWeight.bold,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  '${patient.age} years • ${patient.village}',
                  style:
                      const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  patient.symptoms,
                  maxLines: 1,
                  overflow:
                      TextOverflow.ellipsis,
                  style:
                      const TextStyle(
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          if (showRisk)
            Container(
              padding:
                  const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),

              decoration: BoxDecoration(
                color: isUrgent
                    ? Colors.red
                        .withValues(alpha: .1)
                    : Colors.orange
                        .withValues(alpha: .1),

                borderRadius:
                    BorderRadius.circular(
                  10,
                ),
              ),

              child: Text(
                patient.riskLevel,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                      FontWeight.bold,
                  color: isUrgent
                      ? Colors.red
                      : Colors.orange,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyCard(String message) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),

      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Colors.grey,
        ),
      ),
    );
  }
}
