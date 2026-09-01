import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/patient.dart';
import '../../services/patient_service.dart';
import 'add_patient_screen.dart';

class PatientListScreen extends StatelessWidget {
  PatientListScreen({super.key});

  final PatientService _service =
      PatientService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7FAF9),

      appBar: AppBar(
        title: Text(
          'My Patients',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      floatingActionButton:
          FloatingActionButton.extended(
        backgroundColor:
            const Color(0xFF087F73),

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  const AddPatientScreen(),
            ),
          );
        },

        icon: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),

        label: const Text(
          'Add Patient',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
      ),

      body: StreamBuilder<List<Patient>>(
        stream: _service.getPatients(),

        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
                  CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading patients',
              ),
            );
          }

          final patients =
              snapshot.data ?? [];

          if (patients.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),

            itemCount: patients.length,

            itemBuilder:
                (context, index) {
              return _patientCard(
                context,
                patients[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _patientCard(
    BuildContext context,
    Patient patient,
  ) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 14),

      elevation: 0,

      shape: RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),

        side: const BorderSide(
          color: Color(0xFFE0E9E6),
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 25,

                  backgroundColor:
                      const Color(
                    0xFFE5F5F2,
                  ),

                  child: Text(
                    patient.name.isNotEmpty
                        ? patient.name[0]
                            .toUpperCase()
                        : '?',

                    style: const TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color:
                          Color(0xFF087F73),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        patient.name,
                        style:
                            GoogleFonts.inter(
                          fontSize: 17,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        '${patient.age} years • ${patient.gender}',
                        style:
                            const TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                _statusChip(
                  patient.status,
                ),

                const SizedBox(width: 6),

                _riskChip(
                  patient.riskLevel,
                ),
              ],
            ),

            const SizedBox(height: 14),

            const Divider(),

            const SizedBox(height: 8),

            _infoRow(
              Icons.location_on_outlined,
              patient.village,
            ),

            _infoRow(
              Icons.phone_outlined,
              patient.phone,
            ),

            _infoRow(
              Icons.medical_information_outlined,
              patient.symptoms,
            ),

            if (patient.followUpDate.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F7F7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_month_outlined,
                      size: 20,
                      color: Color(0xFF087F73),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Follow-up: ${patient.followUpDate}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            if (patient.aiRecommendation.isNotEmpty)
              Container(
                margin: const EdgeInsets.only(top: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F7F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 20,
                      color: Color(0xFF087F73),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        patient.aiRecommendation,
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: patient.status == 'Completed'
                    ? null
                    : () async {
                        await _service.updateStatus(
                          patient.id,
                          'Completed',
                        );

                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Follow-up marked as completed',
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(
                  Icons.check_circle_outline,
                ),
                label: Text(
                  patient.status == 'Completed'
                      ? 'FOLLOW-UP COMPLETED'
                      : 'MARK FOLLOW-UP COMPLETE',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 5,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            icon,
            size: 19,
            color:
                const Color(0xFF087F73),
          ),

          const SizedBox(width: 10),

          Expanded(
            child: Text(text),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color:
            status == 'Completed'
                ? Colors.green.shade50
                : Colors.orange.shade50,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        status,

        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color:
              status == 'Completed'
                  ? Colors.green.shade700
                  : Colors.orange.shade700,
        ),
      ),
    );
  }

  Widget _riskChip(String risk) {
    IconData icon;

    if (risk == 'Urgent') {
      icon = Icons.warning_amber_rounded;
    } else if (risk == 'Follow-up') {
      icon = Icons.schedule;
    } else {
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: risk == 'Urgent'
            ? Colors.red.shade50
            : risk == 'Follow-up'
                ? Colors.orange.shade50
                : Colors.green.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: risk == 'Urgent'
                ? Colors.red.shade700
                : risk == 'Follow-up'
                    ? Colors.orange.shade700
                    : Colors.green.shade700,
          ),
          const SizedBox(width: 4),
          Text(
            risk,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: risk == 'Urgent'
                  ? Colors.red.shade700
                  : risk == 'Follow-up'
                      ? Colors.orange.shade700
                      : Colors.green.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Icon(
              Icons.people_outline,
              size: 80,
              color: Color(0xFF087F73),
            ),

            SizedBox(height: 16),

            Text(
              'No patients registered yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'Add your first patient to begin digital follow-up.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
