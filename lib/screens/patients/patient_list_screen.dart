import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/patient.dart';
import '../../services/patient_service.dart';
import 'add_patient_screen.dart';
import 'patient_details_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  final PatientService _service = PatientService();
  final TextEditingController _searchController = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Patient> _applyFilters(List<Patient> patients) {
    final query = _searchController.text.trim().toLowerCase();

    Iterable<Patient> filtered = patients;

    if (query.isNotEmpty) {
      filtered = filtered.where((p) {
        return p.name.toLowerCase().contains(query) ||
            p.village.toLowerCase().contains(query) ||
            p.symptoms.toLowerCase().contains(query);
      });
    }

    if (_filter == 'Urgent') {
      filtered = filtered.where((p) => p.riskLevel.toLowerCase() == 'urgent');
    } else if (_filter == 'Follow-up') {
      filtered = filtered.where((p) => p.riskLevel.toLowerCase() == 'follow-up');
    }

    return filtered.toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: Text(
          'Patients',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF087F73),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const AddPatientScreen(),
            ),
          );
        },
        icon: const Icon(
          Icons.person_add,
          color: Colors.white,
        ),
        label: const Text(
          'Add Patient',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: StreamBuilder<List<Patient>>(
        stream: _service.getPatients(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading patients',
                style: GoogleFonts.inter(),
              ),
            );
          }

          final patients = snapshot.data ?? [];
          final filtered = _applyFilters(patients);

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Search by name, village or symptoms',
                        filled: true,
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE0E9E6),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _filterChip('All'),
                          const SizedBox(width: 8),
                          _filterChip('Urgent'),
                          const SizedBox(width: 8),
                          _filterChip('Follow-up'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(30),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off_rounded,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No patients found',
                                style: GoogleFonts.inter(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          return _patientCard(filtered[index]);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _filterChip(String label) {
    final selected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _filter = label;
        });
      },
      selectedColor: const Color(0xFF087F73),
      labelStyle: GoogleFonts.inter(
        color: selected ? Colors.white : Colors.black87,
        fontWeight: FontWeight.w600,
      ),
      backgroundColor: Colors.white,
      side: const BorderSide(color: Color(0xFFE0E9E6)),
    );
  }

  Widget _patientCard(Patient patient) {
    final isUrgent = patient.riskLevel.toLowerCase() == 'urgent';
    final isFollowUp = patient.riskLevel.toLowerCase() == 'follow-up';

    Color riskColor;
    Color riskBg;
    IconData riskIcon;

    if (isUrgent) {
      riskColor = Colors.red.shade700;
      riskBg = Colors.red.shade50;
      riskIcon = Icons.warning_amber_rounded;
    } else if (isFollowUp) {
      riskColor = Colors.orange.shade700;
      riskBg = Colors.orange.shade50;
      riskIcon = Icons.schedule;
    } else {
      riskColor = Colors.green.shade700;
      riskBg = Colors.green.shade50;
      riskIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE0E9E6)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PatientDetailsScreen(
                patient: patient,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: const Color(0xFFE8F6F3),
                    child: Text(
                      patient.name.isNotEmpty
                          ? patient.name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF087F73),
                        fontSize: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          patient.name,
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${patient.age} years • ${patient.gender}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 13,
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
                      color: riskBg,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          riskIcon,
                          size: 14,
                          color: riskColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          patient.riskLevel.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: riskColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1),
              const SizedBox(height: 10),
              _infoRow(Icons.location_on_outlined, patient.village),
              const SizedBox(height: 6),
              _infoRow(Icons.phone_outlined, patient.phone.isEmpty ? 'No phone' : patient.phone),
              const SizedBox(height: 6),
              _infoRow(Icons.medical_information_outlined, patient.symptoms),
              if (patient.followUpDate.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_month_outlined,
                        size: 18,
                        color: Color(0xFF087F73),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Follow-up: ${patient.followUpDate}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatientDetailsScreen(
                          patient: patient,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_ios, size: 16),
                  label: const Text('VIEW DETAILS'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF087F73)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }
}
