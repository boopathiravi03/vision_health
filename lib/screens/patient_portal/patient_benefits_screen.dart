import 'package:flutter/material.dart';
import '../schemes/scheme_finder_screen.dart';
import '../../services/patient_service.dart';

class PatientBenefitsScreen extends StatefulWidget {
  final String? patientId;

  const PatientBenefitsScreen({super.key, this.patientId});

  @override
  State<PatientBenefitsScreen> createState() => _PatientBenefitsScreenState();
}

class _PatientBenefitsScreenState extends State<PatientBenefitsScreen> {
  final _formKey = GlobalKey<FormState>();

  final _ageController = TextEditingController();
  final _situationController = TextEditingController();

  String _gender = 'Male';
  bool _loadingPatient = false;

  @override
  void initState() {
    super.initState();
    _loadPatientDetails();
  }

  Future<void> _loadPatientDetails() async {
    final patientId = widget.patientId;
    if (patientId == null || patientId.isEmpty) return;

    setState(() => _loadingPatient = true);
    try {
      final patient = await PatientService().getPatient(patientId);
      if (!mounted || patient == null) return;

      final age = int.tryParse(patient['age']?.toString() ?? '');
      final gender = patient['gender']?.toString().trim();
      final symptoms = patient['symptoms'];
      final symptomText = symptoms is List
          ? symptoms.map((item) => item.toString()).join(', ')
          : symptoms?.toString() ?? '';

      setState(() {
        if (age != null && age > 0) _ageController.text = age.toString();
        if (gender == 'Male' || gender == 'Female' || gender == 'Other') {
          _gender = gender!;
        }
        if (symptomText.isNotEmpty) _situationController.text = symptomText;
      });
    } catch (_) {
      // The patient can still enter their details manually.
    } finally {
      if (mounted) setState(() => _loadingPatient = false);
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    _situationController.dispose();
    super.dispose();
  }

  void _findBenefits() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final age = int.parse(_ageController.text.trim());

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchemeFinderScreen(
          age: age,
          gender: _gender,
          situation: _situationController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),

      appBar: AppBar(title: const Text('Government Benefits')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Form(
          key: _formKey,

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              _header(),

              const SizedBox(height: 24),

              if (_loadingPatient)
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: LinearProgressIndicator(),
                ),

              const Text(
                'Your Details',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Age',
                  hintText: 'Enter your age',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                validator: (value) {
                  final age = int.tryParse(value ?? '');

                  if (age == null || age <= 0 || age > 120) {
                    return 'Enter a valid age';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                initialValue: _gender,

                decoration: InputDecoration(
                  labelText: 'Gender',
                  prefixIcon: const Icon(Icons.person_outline),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),

                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],

                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _gender = value;
                  });
                },
              ),

              const SizedBox(height: 14),

              TextFormField(
                controller: _situationController,
                maxLines: 4,

                decoration: InputDecoration(
                  labelText: 'Health situation / reason',
                  hintText:
                      'Example: pregnancy, fever, disability, elderly care...',
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 65),
                    child: Icon(Icons.medical_information_outlined),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),

                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please describe your situation';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 22),

              SizedBox(
                width: double.infinity,
                height: 56,

                child: FilledButton.icon(
                  onPressed: _findBenefits,

                  icon: const Icon(Icons.search_rounded),

                  label: const Text(
                    'FIND MY BENEFITS',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              const SizedBox(height: 18),

              _notice(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F3),
        borderRadius: BorderRadius.circular(22),
      ),

      child: const Column(
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.account_balance_rounded,
              size: 38,
              color: Color(0xFF087F73),
            ),
          ),

          SizedBox(height: 12),

          Text(
            'Find Government Benefits',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF073B36),
            ),
          ),

          SizedBox(height: 7),

          Text(
            'Tell us a little about yourself. '
            'Vission Health will show relevant '
            'health scheme information.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.black54, height: 1.45),
          ),
        ],
      ),
    );
  }

  Widget _notice() {
    return Container(
      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.shade200),
      ),

      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Icon(Icons.info_outline, color: Colors.orange),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Results are preliminary information only. '
              'Actual eligibility must be verified with '
              'the official government authority.',
              style: TextStyle(fontSize: 12, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
