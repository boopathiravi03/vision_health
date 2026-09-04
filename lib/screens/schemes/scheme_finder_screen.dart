import 'package:flutter/material.dart';

import '../../services/scheme_service.dart';
import 'scheme_hospital_map_screen.dart';

class SchemeFinderScreen extends StatefulWidget {
  final String patientName;
  final int age;
  final String gender;
  final String situation;
  final String village;

  const SchemeFinderScreen({
    super.key,
    this.patientName = 'Demo Patient',
    this.age = 31,
    this.gender = 'Male',
    this.situation = 'Fever',
    this.village = 'Chennai',
  });

  @override
  State<SchemeFinderScreen> createState() => _SchemeFinderScreenState();
}

class _SchemeFinderScreenState extends State<SchemeFinderScreen> {
  bool loading = true;
  String? error;

  List<Map<String, dynamic>> schemes = [];

  late int patientAge;
  late String patientGender;
  late String patientSituation;
  late String patientVillage;

  @override
  void initState() {
    super.initState();

    patientAge = widget.age > 0 ? widget.age : 31;
    patientGender =
        widget.gender.trim().isNotEmpty ? widget.gender.trim() : 'Male';
    patientSituation =
        widget.situation.trim().isNotEmpty ? widget.situation.trim() : 'Fever';
    patientVillage =
        widget.village.trim().isNotEmpty ? widget.village.trim() : 'Chennai';

    findSchemes();
  }

  Future<void> findSchemes() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final result = await SchemeService.findSchemes(
        age: patientAge,
        gender: patientGender,
        situation: patientSituation,
      );

      final returnedSchemes = result['schemes'];

      if (!mounted) return;

      if (returnedSchemes is List && returnedSchemes.isNotEmpty) {
        setState(() {
          schemes = returnedSchemes
              .map(
                (e) => Map<String, dynamic>.from(e as Map),
              )
              .toList();
          loading = false;
        });
      } else {
        setState(() {
          schemes = _demoSchemes();
          loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        schemes = _demoSchemes();
        loading = false;
        error = null;
      });
    }
  }

  List<Map<String, dynamic>> _demoSchemes() {
    return [
      {
        'name': 'Pradhan Mantri Jan Arogya Yojana (PMJAY)',
        'description':
            'A national health protection scheme supporting eligible families with hospitalisation coverage.',
        'why_eligible':
            'The patient has a recorded health concern and may require medical evaluation or hospital care.',
        'documents': [
          'Aadhaar Card',
          'Ration Card',
          'Income Certificate if applicable',
        ],
        'where_to_apply':
            'At an eligible PMJAY hospital or through the official PMJAY service.',
        'action':
            'Check eligibility and visit an eligible hospital for verification.',
        'scheme_type': 'hospital',
      },
      {
        'name': 'Ayushman Bharat Health Scheme',
        'description':
            'Government health coverage intended to improve access to affordable healthcare services.',
        'why_eligible':
            'The patient record indicates a current health concern requiring healthcare support.',
        'documents': [
          'Aadhaar Card',
          'Government ID',
          'Family/Ration Card',
        ],
        'where_to_apply':
            'Through an authorised government health facility.',
        'action':
            'Verify eligibility and ask the health facility about available benefits.',
        'scheme_type': 'hospital',
      },
      {
        'name': 'National Health Mission Services',
        'description':
            'Government-supported healthcare services available through public health facilities.',
        'why_eligible':
            'The patient may benefit from public primary and secondary healthcare services.',
        'documents': [
          'Government ID',
          'Patient health record',
        ],
        'where_to_apply':
            'Nearest PHC, government hospital, or designated health facility.',
        'action':
            'Visit the nearest public health facility and show the patient record.',
        'scheme_type': 'phc',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF5F9F8),
        elevation: 0,
        title: const Text(
          'Government Benefits',
          style: TextStyle(
            color: Colors.black,
            fontSize: 21,
            fontWeight: FontWeight.w500,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: loading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF087F73),
              ),
            )
          : _buildContent(),
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroCard(),

          const SizedBox(height: 18),

          _patientRecordCard(),

          const SizedBox(height: 22),

          const Text(
            'Recommended Government Schemes',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),

          const SizedBox(height: 14),

          ...schemes.map(_schemeCard),

          const SizedBox(height: 8),

          _disclaimer(),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      decoration: BoxDecoration(
        color: const Color(0xFFE1F3EF),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance,
              size: 55,
              color: Color(0xFF087F73),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'Government Benefits',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.bold,
              color: Color(0xFF075E56),
            ),
          ),

          const SizedBox(height: 10),

          Text(
            'Benefits are suggested using\ninformation recorded by your ASHA worker.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 17,
              height: 1.5,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientRecordCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Based on your ASHA health record',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF087F73),
            ),
          ),

          const SizedBox(height: 18),

          _recordRow(
            Icons.cake_outlined,
            'Age',
            '$patientAge',
          ),

          _recordRow(
            Icons.person_outline,
            'Gender',
            patientGender,
          ),

          _recordRow(
            Icons.medical_services_outlined,
            'Health concern',
            patientSituation,
          ),

          _recordRow(
            Icons.location_on_outlined,
            'Location',
            patientVillage,
          ),
        ],
      ),
    );
  }

  Widget _recordRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 30,
            color: const Color(0xFF0B9C8C),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 17,
                ),
                children: [
                  TextSpan(
                    text: '$label: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text: value,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _schemeCard(Map<String, dynamic> scheme) {
    final name =
        scheme['name']?.toString() ?? 'Government Health Scheme';

    final description =
        scheme['description']?.toString() ?? '';

    final whyEligible =
        scheme['why_eligible']?.toString() ?? '';

    final whereToApply =
        scheme['where_to_apply']?.toString() ?? '';

    final action =
        scheme['action']?.toString() ?? '';

    final documents = scheme['documents'] is List
        ? (scheme['documents'] as List)
            .map((e) => e.toString())
            .toList()
        : <String>[];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFFE0E9E6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          _item(
            'Description',
            description,
          ),

          _item(
            'Why it may apply',
            whyEligible,
          ),

          if (documents.isNotEmpty)
            _item(
              'Documents',
              documents.join(', '),
            ),

          _item(
            'Where to apply',
            whereToApply,
          ),

          _item(
            'Next action',
            action,
          ),

          const SizedBox(height: 8),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SchemeHospitalMapScreen(
                      scheme: scheme,
                      patientLocation: patientVillage,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.location_on_outlined,
              ),
              label: const Text(
                'FIND HOSPITALS & HOW TO APPLY',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF087F73),
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _item(
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value.isNotEmpty ? value : 'Not specified',
            style: const TextStyle(
              fontSize: 16,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Scheme suggestions are preliminary. Eligibility and hospital participation must be verified with the official government authority or health facility.',
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
