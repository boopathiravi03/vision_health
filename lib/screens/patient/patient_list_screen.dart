import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'health_passport_screen.dart';

class PatientListScreen extends StatelessWidget {
  const PatientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients'),
      ),
      backgroundColor: const Color(0xFFF5F9F8),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('patients')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Unable to load patients.\n\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return _emptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data =
                  doc.data() as Map<String, dynamic>;

              return _patientCard(
                context,
                doc.id,
                data,
              );
            },
          );
        },
      ),
    );
  }

  Widget _patientCard(
    BuildContext context,
    String patientId,
    Map<String, dynamic> data,
  ) {
    final name =
        data['name']?.toString().trim().isNotEmpty == true
            ? data['name'].toString()
            : 'Unknown Patient';

    final age =
        data['age']?.toString() ?? 'N/A';

    final gender =
        data['gender']?.toString() ?? 'N/A';

    final village =
        data['village']?.toString().trim().isNotEmpty == true
            ? data['village'].toString()
            : 'Village not provided';

    final severity =
        data['severity']?.toString() ?? 'Not assessed';

    final symptoms = data['symptoms'];

    String symptomText = 'No symptoms recorded';

    if (symptoms is List && symptoms.isNotEmpty) {
      symptomText = symptoms
          .map((e) => e.toString())
          .join(', ');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2EAE8),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HealthPassportScreen(
                patientId: patientId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor:
                        const Color(0xFFE8F6F3),
                    child: const Icon(
                      Icons.person,
                      color: Color(0xFF087F73),
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 4),

                        Text(
                          '$age years • $gender',
                          style: const TextStyle(
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Row(
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 18,
                    color: Color(0xFF087F73),
                  ),

                  const SizedBox(width: 5),

                  Expanded(
                    child: Text(
                      village,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                'Symptoms',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                symptomText,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  _riskBadge(severity),

                  const Spacer(),

                  const Text(
                    'VIEW PASSPORT',
                    style: TextStyle(
                      color: Color(0xFF087F73),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
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

  Widget _riskBadge(String severity) {
    String label = severity;

    Color background =
        const Color(0xFFE8F6F3);

    Color foreground =
        const Color(0xFF087F73);

    final value = severity.toLowerCase();

    if (value.contains('severe') ||
        value.contains('high') ||
        value.contains('urgent')) {
      label = 'HIGH';
      background = Colors.red.shade50;
      foreground = Colors.red.shade700;
    } else if (value.contains('moderate') ||
        value.contains('medium')) {
      label = 'MODERATE';
      background = Colors.orange.shade50;
      foreground = Colors.orange.shade800;
    } else if (value.contains('mild') ||
        value.contains('low')) {
      label = 'LOW';
    } else {
      label = 'NOT ASSESSED';
      background = Colors.grey.shade100;
      foreground = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.people_outline,
              size: 70,
              color: Color(0xFF087F73),
            ),

            const SizedBox(height: 18),

            const Text(
              'No patients yet',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Patients created through Voice-to-Form will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(context);
              },
              icon: const Icon(Icons.mic),
              label: const Text('CREATE PATIENT'),
            ),
          ],
        ),
      ),
    );
  }
}
