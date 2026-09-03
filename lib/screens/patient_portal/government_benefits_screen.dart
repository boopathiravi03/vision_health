import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../schemes/scheme_hospitals_screen.dart';

class GovernmentBenefitsScreen extends StatefulWidget {
  const GovernmentBenefitsScreen({super.key});

  @override
  State<GovernmentBenefitsScreen> createState() =>
      _GovernmentBenefitsScreenState();
}

class _GovernmentBenefitsScreenState
    extends State<GovernmentBenefitsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? patient;
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        setState(() {
          loading = false;
          error = 'Please login to continue.';
        });
        return;
      }

      QuerySnapshot snapshot = await _firestore
          .collection('patients')
          .where('patientAuthUid', isEqualTo: user.uid)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection('patients')
            .where('authUid', isEqualTo: user.uid)
            .limit(1)
            .get();
      }

      if (snapshot.docs.isEmpty) {
        setState(() {
          loading = false;
          error =
              'Your health record is not linked to an ASHA record yet.';
        });
        return;
      }

      setState(() {
        patient = snapshot.docs.first.data() as Map<String, dynamic>;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = 'Unable to load your health record.';
      });
    }
  }

  String _value(List<String> keys, {String fallback = 'Not available'}) {
    final data = patient ?? {};

    for (final key in keys) {
      final value = data[key];

      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }

    return fallback;
  }

  void _openScheme(Map<String, dynamic> scheme) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SchemeHospitalsScreen(
          scheme: scheme,
          patient: patient ?? {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xffF5FAF9),
        elevation: 0,
        title: const Text(
          'Government Benefits',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
        leading: const BackButton(color: Colors.black),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? _errorView()
              : _content(),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.person_off_outlined,
              size: 60,
              color: Colors.teal,
            ),
            const SizedBox(height: 20),
            Text(
              error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loadPatient,
              child: const Text('TRY AGAIN'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content() {
    final age = _value(['age', 'patientAge']);
    final gender = _value(['gender', 'sex']);
    final health = _value([
      'healthSituation',
      'health_situation',
      'reason',
      'symptoms',
      'healthConcern',
    ]);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _header(),

        const SizedBox(height: 18),

        _patientSummary(
          age: age,
          gender: gender,
          health: health,
        ),

        const SizedBox(height: 24),

        const Text(
          'Recommended Government Schemes',
          style: TextStyle(
            fontSize: 23,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 14),

        _schemeCard(
          name: 'Pradhan Mantri Jan Arogya Yojana (PMJAY)',
          description:
              'A national health protection scheme supporting eligible families with hospitalisation coverage.',
          why:
              'Your ASHA-recorded health information can be used as an initial guide to identify potentially relevant benefits.',
          documents:
              'Aadhaar Card, eligibility/family identification documents and other documents requested by the official authority.',
          apply:
              'Check eligibility through the official PMJAY system or visit an authorised health facility.',
          action:
              'Verify eligibility and visit an authorised/empanelled hospital.',
          schemeType: 'PMJAY',
        ),

        const SizedBox(height: 16),

        _schemeCard(
          name: 'State Health Insurance Benefits',
          description:
              'Health insurance support available through eligible state healthcare programmes.',
          why:
              'Your patient profile may match eligibility conditions depending on state rules and household status.',
          documents:
              'Government ID, income/family documents and other state-specific documents.',
          apply:
              'Visit the appropriate government health office or authorised hospital.',
          action:
              'Confirm eligibility before starting registration.',
          schemeType: 'STATE_HEALTH',
        ),

        const SizedBox(height: 25),

        _warning(),
      ],
    );
  }

  Widget _header() {
    return Container(
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: const Color(0xffE4F5F2),
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_balance,
            size: 65,
            color: Color(0xff00796B),
          ),
          SizedBox(height: 15),
          Text(
            'Government Benefits',
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: Color(0xff004D40),
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Benefits are suggested using information recorded by your ASHA worker.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _patientSummary({
    required String age,
    required String gender,
    required String health,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Based on your ASHA health record',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xff00695C),
            ),
          ),
          const SizedBox(height: 15),
          _infoRow(Icons.cake_outlined, 'Age', age),
          _infoRow(Icons.person_outline, 'Gender', gender),
          _infoRow(
            Icons.medical_services_outlined,
            'Health concern',
            health,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(
    IconData icon,
    String title,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.teal),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                ),
                children: [
                  TextSpan(
                    text: '$title: ',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _schemeCard({
    required String name,
    required String description,
    required String why,
    required String documents,
    required String apply,
    required String action,
    required String schemeType,
  }) {
    final scheme = {
      'name': name,
      'description': description,
      'why': why,
      'documents': documents,
      'apply': apply,
      'action': action,
      'schemeType': schemeType,
    };

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 18),

          _section('Description', description),
          _section('Why it may apply', why),
          _section('Documents', documents),
          _section('Where / How to apply', apply),
          _section('Next action', action),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _openScheme(scheme),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text(
                'FIND HOSPITALS & HOW TO APPLY',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff00796B),
                foregroundColor: Colors.white,
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

  Widget _section(String title, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warning() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xfffff8df),
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Scheme eligibility is not confirmed by AI. '
              'Verify eligibility and current requirements with '
              'the official government source or PHC.',
            ),
          ),
        ],
      ),
    );
  }
}
