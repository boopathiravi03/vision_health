import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'health_passport_screen.dart';
import '../schemes/scheme_finder_screen.dart';

enum PatientSelectionAction { triage, schemes }

class PatientListScreen extends StatefulWidget {
  final PatientSelectionAction? action;

  const PatientListScreen({
    super.key,
    this.action,
  });

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final TextEditingController searchController = TextEditingController();

  String searchText = '';

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  bool matchesSearch(Map<String, dynamic> data) {
    if (searchText.trim().isEmpty) {
      return true;
    }

    final query = searchText.trim().toLowerCase();

    final name = data['name']?.toString().toLowerCase() ?? '';

    final village = data['village']?.toString().toLowerCase() ?? '';

    final phone = data['phone']?.toString().toLowerCase() ?? '';

    return name.contains(query) ||
        village.contains(query) ||
        phone.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Patients',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      backgroundColor: const Color(0xFFF5F9F8),

      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.touch_app_rounded, color: Color(0xFF087F73)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Select a patient to view their health record, run AI Triage, or find Government Schemes.',
                      style: TextStyle(fontSize: 13, height: 1.4, color: Color(0xFF245A54)),
                    ),
                  ),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: TextField(
              controller: searchController,
              onChanged: (value) {
                setState(() {
                  searchText = value;
                });
              },
              decoration: InputDecoration(
                hintText: 'Search name, village or phone...',
                prefixIcon: const Icon(Icons.search, color: Color(0xFF087F73)),
                suffixIcon: searchText.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          searchController.clear();
                          setState(() {
                            searchText = '';
                          });
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('patients')
                  .snapshots(),

              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
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

                final filteredDocs = docs.where((doc) {
                  return matchesSearch(doc.data());
                }).toList();

                if (docs.isEmpty) {
                  return _emptyState(
                    context,
                    'No patients yet',
                    'Patients created through Voice-to-Form will appear here.',
                  );
                }

                if (filteredDocs.isEmpty) {
                  return _emptyState(
                    context,
                    'No matching patients',
                    'Try searching with another name, village or phone number.',
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  itemCount: filteredDocs.length,
                  itemBuilder: (context, index) {
                    final doc = filteredDocs[index];

                    return _patientCard(context, doc.id, doc.data());
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientCard(
    BuildContext context,
    String patientId,
    Map<String, dynamic> data,
  ) {
    final name = data['name']?.toString().trim().isNotEmpty == true
        ? data['name'].toString()
        : 'Unknown Patient';

    final age = data['age']?.toString() ?? 'N/A';

    final gender = data['gender']?.toString() ?? 'N/A';

    final village = data['village']?.toString().trim().isNotEmpty == true
        ? data['village'].toString()
        : 'Village not provided';

    final symptoms = data['symptoms'];

    final severity =
        data['severity']?.toString() ??
            data['riskLevel']?.toString() ??
            'Not assessed';

    String symptomText = 'No symptoms recorded';

    if (symptoms is List && symptoms.isNotEmpty) {
      symptomText = symptoms.map((e) => e.toString()).join(', ');
    } else if (symptoms != null) {
      symptomText = symptoms.toString();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2EAE8)),
      ),

      child: InkWell(
        borderRadius: BorderRadius.circular(20),

        onTap: () {
          if (widget.action == PatientSelectionAction.triage) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HealthPassportScreen(
                  patientId: patientId,
                ),
              ),
            );
          } else if (widget.action == PatientSelectionAction.schemes) {
            final patientAge = int.tryParse(age) ?? 0;
            final patientGender = gender;

            String situation = '';
            if (symptoms is List) {
              situation = symptoms.map((e) => e.toString()).join(', ');
            } else if (symptoms != null) {
              situation = symptoms.toString();
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SchemeFinderScreen(
                  age: patientAge,
                  gender: patientGender,
                  situation: situation,
                ),
              ),
            );
          } else {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HealthPassportScreen(
                  patientId: patientId,
                ),
              ),
            );
          }
        },

        child: Padding(
          padding: const EdgeInsets.all(18),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 27,
                    backgroundColor: const Color(0xFFE8F6F3),

                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',

                      style: const TextStyle(
                        color: Color(0xFF087F73),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                  const SizedBox(width: 14),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
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
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),

                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') {
                        _deletePatient(patientId, name);
                      }
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
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
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                'Symptoms',
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 3),

              Text(symptomText, maxLines: 2, overflow: TextOverflow.ellipsis),

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

                  const SizedBox(width: 4),

                  const Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: Color(0xFF087F73),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              if (widget.action == null) ...[
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => HealthPassportScreen(
                                patientId: patientId,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.medical_services_outlined, size: 18),
                        label: const Text('AI TRIAGE'),
                      ),
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () {
                          final patientAge = int.tryParse(age) ?? 0;
                          final patientGender = gender;

                          String situation = '';
                          if (symptoms is List) {
                            situation = symptoms.map((e) => e.toString()).join(', ');
                          } else if (symptoms != null) {
                            situation = symptoms.toString();
                          }

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => SchemeFinderScreen(
                                age: patientAge,
                                gender: patientGender,
                                situation: situation,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.account_balance, size: 18),
                        label: const Text('SCHEMES'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _riskBadge(String severity) {
    String label = severity.toUpperCase();

    Color background = const Color(0xFFE8F6F3);

    Color foreground = const Color(0xFF087F73);

    final value = severity.toLowerCase();

    if (value.contains('severe') ||
        value.contains('high') ||
        value.contains('urgent')) {
      label = 'HIGH';
      background = Colors.red.shade50;
      foreground = Colors.red.shade700;
    } else if (value.contains('moderate') || value.contains('medium')) {
      label = 'MODERATE';
      background = Colors.orange.shade50;
      foreground = Colors.orange.shade800;
    } else if (value.contains('mild') || value.contains('low')) {
      label = 'LOW';
    } else {
      label = 'NOT ASSESSED';
      background = Colors.grey.shade100;
      foreground = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

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

  Future<void> _deletePatient(
    String patientId,
    String name,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete patient?'),
          content: Text('Are you sure you want to delete $name\'s record?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('DELETE'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('patients')
          .doc(patientId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Patient deleted.')));
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Widget _emptyState(BuildContext context, String title, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            const Icon(
              Icons.people_outline,
              size: 70,
              color: Color(0xFF087F73),
            ),

            const SizedBox(height: 18),

            Text(
              title,
              style: const TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 8),

            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}
