import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../schemes/scheme_hospitals_screen.dart';

class GovernmentBenefitsScreen extends StatefulWidget {
  const GovernmentBenefitsScreen({
    super.key,
  });

  @override
  State<GovernmentBenefitsScreen> createState() =>
      _GovernmentBenefitsScreenState();
}

class _GovernmentBenefitsScreenState
    extends State<GovernmentBenefitsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  Map<String, dynamic>? patient;

  bool loading = true;

  String? error;

  // ------------------------------------------------------------
  // COMPLETE DEMO PATIENT
  // ------------------------------------------------------------

  final Map<String, dynamic> _demoPatient = {
    'id': 'demo-patient-001',
    'name': 'Arun Kumar',
    'age': 31,
    'gender': 'Male',
    'village': 'Anna Nagar',
    'town': 'Chennai',
    'city': 'Chennai',
    'district': 'Chennai',
    'state': 'Tamil Nadu',
    'pincode': '600040',
    'phone': '9876543210',
    'symptoms': 'Fever',
    'healthSituation': 'Fever',
    'healthConcern': 'Fever and mild weakness',
    'status': 'Active',
    'riskLevel': 'Routine',
    'followUpDate': '15 September 2026',
    'bloodGroup': 'B+',
    'emergencyContact': '9876501234',
    'emergencyContactName': 'Family Member',
    'createdBy': 'demo-asha-worker',
    'recordedBy': 'ASHA Worker',
  };

  @override
  void initState() {
    super.initState();

    _loadPatient();
  }

  // ------------------------------------------------------------
  // LOAD ASHA PATIENT
  // ------------------------------------------------------------

  Future<void> _loadPatient() async {
    try {
      final user =
          FirebaseAuth.instance.currentUser;

      if (user == null) {
        _useDemoPatient(
          'Demo patient loaded for demonstration.',
        );
        return;
      }

      QuerySnapshot snapshot =
          await _firestore
              .collection('patients')
              .where(
                'patientAuthUid',
                isEqualTo: user.uid,
              )
              .limit(1)
              .get();

      if (snapshot.docs.isEmpty) {
        snapshot =
            await _firestore
                .collection('patients')
                .where(
                  'authUid',
                  isEqualTo: user.uid,
                )
                .limit(1)
                .get();
      }

      if (snapshot.docs.isEmpty) {
        _useDemoPatient(
          'No linked ASHA record found. Demo patient data is being shown.',
        );
        return;
      }

      final document =
          snapshot.docs.first;

      final data =
          Map<String, dynamic>.from(
        document.data()
            as Map<String, dynamic>,
      );

      data['id'] = document.id;

      if (!mounted) return;

      setState(() {
        patient = {
          ..._demoPatient,
          ...data,
        };

        loading = false;
        error = null;
      });
    } catch (_) {
      _useDemoPatient(
        'Unable to load the ASHA record. Demo patient data is being shown.',
      );
    }
  }

  void _useDemoPatient(
    String message,
  ) {
    if (!mounted) return;

    setState(() {
      patient =
          Map<String, dynamic>.from(
        _demoPatient,
      );

      loading = false;

      error = message;
    });
  }

  // ------------------------------------------------------------
  // HELPERS
  // ------------------------------------------------------------

  String _value(
    List<String> keys, {
    String fallback = 'Not available',
  }) {
    final data = patient ?? {};

    for (final key in keys) {
      final value = data[key];

      if (value != null &&
          value.toString().trim().isNotEmpty) {
        return value.toString().trim();
      }
    }

    return fallback;
  }

  int _age() {
    final value = patient?['age'];

    if (value is int) {
      return value;
    }

    return int.tryParse(
          value?.toString() ?? '',
        ) ??
        31;
  }

  String _healthConcern() {
    return _value(
      [
        'healthSituation',
        'health_situation',
        'healthConcern',
        'symptoms',
        'reason',
      ],
      fallback: 'Fever',
    );
  }

  // ------------------------------------------------------------
  // OPEN HOSPITAL MAP
  // ------------------------------------------------------------

  void _openScheme(
    Map<String, dynamic> scheme,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            SchemeHospitalsScreen(
          scheme: scheme,
          patient: patient ?? _demoPatient,
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          const Color(0xFFF5FAF9),
      appBar: AppBar(
        backgroundColor:
            const Color(0xFFF5FAF9),
        elevation: 0,
        leading: const BackButton(
          color: Colors.black,
        ),
        title: const Text(
          'Government Benefits',
          style: TextStyle(
            color: Colors.black,
            fontWeight:
                FontWeight.w500,
          ),
        ),
      ),
      body: loading
          ? const Center(
              child:
                  CircularProgressIndicator(),
            )
          : _content(),
    );
  }

  Widget _content() {
    final patientName =
        _value(
      ['name', 'patientName'],
      fallback: 'Demo Patient',
    );

    return ListView(
      padding:
          const EdgeInsets.all(16),
      children: [
        _header(),

        const SizedBox(
          height: 18,
        ),

        if (error != null)
          _demoNotice(),

        _patientSummary(
          patientName: patientName,
          age: _age(),
          gender: _value(
            ['gender', 'sex'],
            fallback: 'Male',
          ),
          village: _value(
            [
              'village',
              'town',
              'city',
            ],
            fallback: 'Chennai',
          ),
          district: _value(
            ['district'],
            fallback: 'Chennai',
          ),
          state: _value(
            ['state'],
            fallback: 'Tamil Nadu',
          ),
          health: _healthConcern(),
        ),

        const SizedBox(
          height: 24,
        ),

        const Text(
          'Recommended Government Schemes',
          style: TextStyle(
            fontSize: 23,
            fontWeight:
                FontWeight.bold,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        _schemeCard(
          name:
              'Pradhan Mantri Jan Arogya Yojana (PMJAY)',
          description:
              'A national health protection scheme supporting eligible families with hospitalisation coverage.',
          why:
              'The patient health record can be used as an initial guide. Actual eligibility must be verified through the official scheme system.',
          documents:
              'Government ID, family/eligibility documents and other documents requested by the authorised authority.',
          apply:
              'Check eligibility through the official PMJAY system or an authorised health facility.',
          action:
              'Verify eligibility and visit an authorised/empanelled hospital.',
          schemeType: 'PMJAY',
        ),

        const SizedBox(
          height: 14,
        ),

        _schemeCard(
          name:
              'Tamil Nadu Chief Minister Health Insurance Scheme',
          description:
              'State healthcare support for eligible beneficiaries through authorised healthcare facilities.',
          why:
              'The patient record can help identify a potentially relevant state health benefit.',
          documents:
              'Government ID, family/eligibility documents and scheme-specific records.',
          apply:
              'Visit an authorised government health facility or scheme help desk.',
          action:
              'Confirm eligibility and hospital availability before treatment.',
          schemeType: 'CMCHIS',
        ),

        const SizedBox(
          height: 14,
        ),

        _schemeCard(
          name:
              'Government Primary Healthcare Support',
          description:
              'Access to government primary healthcare services through nearby PHCs and community health facilities.',
          why:
              'The patient location and health concern can help identify nearby government healthcare facilities.',
          documents:
              'Government ID and available health records.',
          apply:
              'Visit the nearest PHC or government healthcare centre.',
          action:
              'Use the map to find a nearby healthcare facility and confirm available services.',
          schemeType: 'PHC',
        ),

        const SizedBox(
          height: 14,
        ),

        _schemeCard(
          name:
              'Maternal & Family Health Services',
          description:
              'Government-supported maternal, family and preventive healthcare services for eligible beneficiaries.',
          why:
              'Relevant patient demographic and health information can help identify appropriate government services.',
          documents:
              'Government ID, maternal/family health records where applicable.',
          apply:
              'Contact the nearest government health centre.',
          action:
              'Ask the healthcare worker to verify the appropriate service.',
          schemeType: 'FAMILY_HEALTH',
        ),

        const SizedBox(
          height: 25,
        ),

        _warning(),
      ],
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _header() {
    return Container(
      padding:
          const EdgeInsets.all(25),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFE4F5F2),
        borderRadius:
            BorderRadius.circular(
          28,
        ),
      ),
      child: const Column(
        children: [
          Icon(
            Icons.account_balance,
            size: 65,
            color: Color(0xFF00796B),
          ),
          SizedBox(
            height: 15,
          ),
          Text(
            'Government Benefits',
            style: TextStyle(
              fontSize: 27,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF004D40),
            ),
          ),
          SizedBox(
            height: 8,
          ),
          Text(
            'Benefits are suggested using information recorded by your ASHA worker.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _demoNotice() {
    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 14,
      ),
      padding:
          const EdgeInsets.all(13),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFFF8E1),
        borderRadius:
            BorderRadius.circular(
          14,
        ),
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            color: Colors.orange,
          ),
          const SizedBox(
            width: 10,
          ),
          Expanded(
            child: Text(
              error!,
              style:
                  const TextStyle(
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // PATIENT SUMMARY
  // ------------------------------------------------------------

  Widget _patientSummary({
    required String patientName,
    required int age,
    required String gender,
    required String village,
    required String district,
    required String state,
    required String health,
  }) {
    return Container(
      padding:
          const EdgeInsets.all(18),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Based on your ASHA health record',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
              color:
                  Color(0xFF00695C),
            ),
          ),

          const SizedBox(
            height: 15,
          ),

          _infoRow(
            Icons.person_outline,
            'Patient',
            patientName,
          ),

          _infoRow(
            Icons.cake_outlined,
            'Age',
            '$age years',
          ),

          _infoRow(
            Icons.wc_outlined,
            'Gender',
            gender,
          ),

          _infoRow(
            Icons.location_on_outlined,
            'Location',
            '$village, $district, $state',
          ),

          _infoRow(
            Icons.medical_services_outlined,
            'Health concern',
            health,
          ),

          _infoRow(
            Icons.badge_outlined,
            'Record source',
            'ASHA Worker',
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
      padding:
          const EdgeInsets.only(
        bottom: 11,
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            color:
                const Color(0xFF087F73),
          ),
          const SizedBox(
            width: 12,
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style:
                    const TextStyle(
                  color:
                      Colors.black87,
                  fontSize: 15,
                ),
                children: [
                  TextSpan(
                    text:
                        '$title: ',
                    style:
                        const TextStyle(
                      fontWeight:
                          FontWeight.bold,
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

  // ------------------------------------------------------------
  // SCHEME CARD
  // ------------------------------------------------------------

  Widget _schemeCard({
    required String name,
    required String description,
    required String why,
    required String documents,
    required String apply,
    required String action,
    required String schemeType,
  }) {
    final scheme =
        <String, dynamic>{
      'name': name,
      'description':
          description,
      'why': why,
      'why_eligible': why,
      'documents':
          documents,
      'where_to_apply':
          apply,
      'action': action,
      'schemeType':
          schemeType,
    };

    return Container(
      padding:
          const EdgeInsets.all(20),
      decoration:
          BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(
          22,
        ),
        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style:
                const TextStyle(
              fontSize: 20,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(
            height: 16,
          ),

          _section(
            'Description',
            description,
          ),

          _section(
            'Why it may apply',
            why,
          ),

          _section(
            'Documents',
            documents,
          ),

          _section(
            'Where / How to apply',
            apply,
          ),

          _section(
            'Next action',
            action,
          ),

          const SizedBox(
            height: 6,
          ),

          Container(
            padding:
                const EdgeInsets.all(
              12,
            ),
            decoration:
                BoxDecoration(
              color:
                  const Color(
              0xFFE8F6F3,
            ),
              borderRadius:
                  BorderRadius.circular(
                14,
              ),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.map_outlined,
                  color:
                      Color(0xFF087F73),
                ),
                SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: Text(
                    'Find nearby healthcare facilities using the patient location.',
                    style:
                        TextStyle(
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          SizedBox(
            width:
                double.infinity,
            child:
                FilledButton.icon(
              onPressed: () =>
                  _openScheme(
                scheme,
              ),
              icon:
                  const Icon(
                Icons.location_on_outlined,
              ),
              label:
                  const Text(
                'FIND HOSPITALS & HOW TO APPLY',
              ),
              style:
                  FilledButton.styleFrom(
                backgroundColor:
                    const Color(
                  0xFF087F73,
                ),
                foregroundColor:
                    Colors.white,
                padding:
                    const EdgeInsets
                        .symmetric(
                  vertical: 15,
                ),
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    30,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    String text,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 14,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style:
                const TextStyle(
              color: Colors.grey,
              fontSize: 13,
            ),
          ),
          const SizedBox(
            height: 4,
          ),
          Text(
            text,
            style:
                const TextStyle(
              fontSize: 15,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _warning() {
    return Container(
      padding:
          const EdgeInsets.all(17),
      decoration:
          BoxDecoration(
        color:
            const Color(0xFFFFF8E1),
        borderRadius:
            BorderRadius.circular(
          18,
        ),
      ),
      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: Colors.orange,
          ),
          SizedBox(
            width: 12,
          ),
          Expanded(
            child: Text(
              'Scheme eligibility is not confirmed by AI. Verify eligibility, hospital empanelment and current requirements with the official government authority or healthcare facility.',
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
