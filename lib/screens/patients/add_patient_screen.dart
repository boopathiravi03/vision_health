import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/patient.dart';
import '../../services/alert_service.dart';
import '../../services/patient_service.dart';
import '../../services/risk_service.dart';

class AddPatientScreen extends StatefulWidget {
  const AddPatientScreen({super.key});

  @override
  State<AddPatientScreen> createState() =>
      _AddPatientScreenState();
}

class _AddPatientScreenState
    extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController =
      TextEditingController();

  final _ageController =
      TextEditingController();

  final _villageController =
      TextEditingController();

  final _phoneController =
      TextEditingController();

  final _symptomsController =
      TextEditingController();

  final PatientService _patientService =
      PatientService();

  final RiskService _riskService =
      RiskService();

  final AlertService _alertService =
      AlertService();

  String _gender = 'Female';

  bool _saving = false;

  Future<void> _savePatient() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    final symptoms =
        _symptomsController.text.trim();

    final risk =
        _riskService.assess(
      age: int.parse(
        _ageController.text.trim(),
      ),
      gender: _gender,
      symptoms: symptoms,
    );

    final now = DateTime.now();

    DateTime followUp;

    if (risk.level == 'Urgent') {
      followUp = now;
    } else if (risk.level == 'Follow-up') {
      followUp = now.add(
        const Duration(days: 1),
      );
    } else {
      followUp = now.add(
        const Duration(days: 7),
      );
    }

    final followUpDate =
        DateFormat('yyyy-MM-dd').format(
      followUp,
    );

    final patient = Patient(
      id: '',
      name: _nameController.text.trim(),
      age: int.parse(
        _ageController.text.trim(),
      ),
      gender: _gender,
      village:
          _villageController.text.trim(),
      phone:
          _phoneController.text.trim(),
      symptoms: symptoms,
      status: 'Pending',
      followUpDate: followUpDate,
      riskLevel: risk.level,
      aiRecommendation:
          risk.recommendation,
    );

    try {
      final patientId =
          await _patientService.addPatient(
        patient,
      );

      if (risk.level == 'Urgent') {
        await _alertService.createAlert(
          patientId: patientId,
          patientName: patient.name,
          riskLevel: risk.level,
          symptoms: patient.symptoms,
          recommendation:
              patient.aiRecommendation,
          village: patient.village,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Patient registered successfully',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content: Text(
            'Unable to save patient: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _villageController.dispose();
    _phoneController.dispose();
    _symptomsController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF7FAF9),

      appBar: AppBar(
        title: Text(
          'Register Patient',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),

      body: Form(
        key: _formKey,

        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              _header(),

              const SizedBox(height: 25),

              _field(
                controller: _nameController,
                label: 'Patient Name',
                icon: Icons.person_outline,
              ),

              const SizedBox(height: 15),

              _field(
                controller: _ageController,
                label: 'Age',
                icon: Icons.cake_outlined,
                keyboardType:
                    TextInputType.number,
              ),

              const SizedBox(height: 15),

              DropdownButtonFormField<String>(
                initialValue: _gender,

                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(
                    Icons.wc_outlined,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border:
                      OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(
                      14,
                    ),
                  ),
                ),

                items: const [
                  DropdownMenuItem(
                    value: 'Female',
                    child: Text('Female'),
                  ),
                  DropdownMenuItem(
                    value: 'Male',
                    child: Text('Male'),
                  ),
                  DropdownMenuItem(
                    value: 'Other',
                    child: Text('Other'),
                  ),
                ],

                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _gender = value;
                    });
                  }
                },
              ),

              const SizedBox(height: 15),

              _field(
                controller:
                    _villageController,
                label: 'Village',
                icon:
                    Icons.location_on_outlined,
              ),

              const SizedBox(height: 15),

              _field(
                controller: _phoneController,
                label: 'Phone Number',
                icon:
                    Icons.phone_outlined,
                keyboardType:
                    TextInputType.phone,
              ),

              const SizedBox(height: 15),

              _field(
                controller:
                    _symptomsController,
                label: 'Symptoms / Health Concern',
                icon:
                    Icons.health_and_safety_outlined,
                maxLines: 4,
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 54,

                child: FilledButton.icon(
                  onPressed:
                      _saving
                          ? null
                          : _savePatient,

                  icon: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color:
                                Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.save_outlined,
                        ),

                  label: Text(
                    _saving
                        ? 'SAVING...'
                        : 'REGISTER PATIENT',
                  ),

                  style:
                      FilledButton.styleFrom(
                    backgroundColor:
                        const Color(
                      0xFF087F73,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: const Color(0xFFE5F5F2),
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Row(
        children: [
          Icon(
            Icons.person_add_alt_1,
            size: 38,
            color: Color(0xFF087F73),
          ),

          SizedBox(width: 14),

          Expanded(
            child: Text(
              'Create a digital patient record for follow-up and continuity of care.',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,

      validator: (value) {
        if (value == null ||
            value.trim().isEmpty) {
          return 'Please enter $label';
        }

        return null;
      },

      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Padding(
          padding:
              const EdgeInsets.only(
            bottom: 0,
          ),
          child: Icon(icon),
        ),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }
}
