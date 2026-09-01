import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/patient.dart';
import '../../services/patient_service.dart';

class FollowUpScreen extends StatelessWidget {
  FollowUpScreen({super.key});

  final PatientService _service =
      PatientService();

  bool _isDue(Patient patient) {
    if (patient.followUpDate.isEmpty ||
        patient.status == 'Completed') {
      return false;
    }

    final date = DateTime.tryParse(
      patient.followUpDate,
    );

    if (date == null) return false;

    final today = DateTime.now();

    final todayOnly = DateTime(
      today.year,
      today.month,
      today.day,
    );

    return !date.isAfter(todayOnly);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7FAF9),

      appBar: AppBar(
        title: Text(
          'Follow-Up Queue',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
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
            return const Center(
              child: Text(
                'Unable to load follow-ups',
              ),
            );
          }

          final patients =
              snapshot.data ?? [];

          final followUps = patients
              .where(
                (patient) =>
                    patient.status !=
                        'Completed' &&
                    patient.followUpDate.isNotEmpty,
              )
              .toList();

          followUps.sort((a, b) {
            final aDate =
                DateTime.tryParse(
                      a.followUpDate,
                    ) ??
                    DateTime(9999);

            final bDate =
                DateTime.tryParse(
                      b.followUpDate,
                    ) ??
                    DateTime(9999);

            return aDate.compareTo(bDate);
          });

          if (followUps.isEmpty) {
            return _emptyState();
          }

          return ListView.builder(
            padding:
                const EdgeInsets.all(16),
            itemCount: followUps.length,
            itemBuilder:
                (context, index) {
              return _followUpCard(
                context,
                followUps[index],
              );
            },
          );
        },
      ),
    );
  }

  Widget _followUpCard(
    BuildContext context,
    Patient patient,
  ) {
    final due = _isDue(patient);

    final parsedDate =
        DateTime.tryParse(
      patient.followUpDate,
    );

    final formattedDate =
        parsedDate == null
            ? patient.followUpDate
            : DateFormat(
                'dd MMM yyyy',
              ).format(parsedDate);

    return Container(
      margin:
          const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color: due
              ? Colors.red.shade200
              : const Color(0xFFE0E9E6),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    const Color(0xFFE5F5F2),

                child: Text(
                  patient.name.isNotEmpty
                      ? patient.name[0]
                          .toUpperCase()
                      : '?',

                  style: const TextStyle(
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
                          GoogleFonts.inter(
                        fontSize: 17,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    Text(
                      '${patient.age} years • ${patient.village}',
                      style:
                          const TextStyle(
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              _riskChip(
                patient.riskLevel,
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding:
                const EdgeInsets.all(12),

            decoration: BoxDecoration(
              color: due
                  ? Colors.red.shade50
                  : Colors.orange.shade50,

              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Row(
              children: [
                Icon(
                  due
                      ? Icons.warning_amber
                      : Icons.calendar_today,
                  color: due
                      ? Colors.red.shade700
                      : Colors.orange.shade700,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    due
                        ? 'Follow-up due today'
                        : 'Follow-up: $formattedDate',
                    style: TextStyle(
                      fontWeight:
                          FontWeight.bold,
                      color: due
                          ? Colors.red.shade700
                          : Colors.orange.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          Text(
            patient.symptoms,
            style: const TextStyle(
              height: 1.4,
            ),
          ),

          const SizedBox(height: 14),

          SizedBox(
            width: double.infinity,

            child: FilledButton.icon(
              onPressed: () async {
                await _service.updateStatus(
                  patient.id,
                  'Completed',
                );

                if (context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Follow-up completed',
                      ),
                    ),
                  );
                }
              },

              icon: const Icon(
                Icons.check,
              ),

              label: const Text(
                'COMPLETE FOLLOW-UP',
              ),

              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(0xFF087F73),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskChip(String risk) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),

      decoration: BoxDecoration(
        color: risk == 'Urgent'
            ? Colors.red.shade50
            : risk == 'Follow-up'
                ? Colors.orange.shade50
                : Colors.green.shade50,

        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
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
              Icons.event_available,
              size: 75,
              color: Color(0xFF087F73),
            ),

            SizedBox(height: 18),

            Text(
              'No pending follow-ups',
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 8),

            Text(
              'All scheduled patient follow-ups are completed.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
