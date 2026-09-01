import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/health_scheme.dart';
import '../../services/scheme_service.dart';

class SchemeFinderScreen extends StatefulWidget {
  const SchemeFinderScreen({super.key});

  @override
  State<SchemeFinderScreen> createState() =>
      _SchemeFinderScreenState();
}

class _SchemeFinderScreenState
    extends State<SchemeFinderScreen> {
  final SchemeService _service =
      SchemeService();

  final TextEditingController _ageController =
      TextEditingController();

  final TextEditingController _situationController =
      TextEditingController();

  String _gender = 'Female';

  bool _loading = false;

  List<HealthScheme> _schemes = [];

  Future<void> _findSchemes() async {
    final age = int.tryParse(
      _ageController.text.trim(),
    );

    if (age == null || age <= 0) {
      _showMessage('Enter a valid age.');
      return;
    }

    if (_situationController.text.trim().isEmpty) {
      _showMessage(
        'Describe the patient situation.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _schemes = [];
    });

    try {
      final schemes =
          _service.findRelevantSchemes(
        age: age,
        gender: _gender,
        symptoms:
            _situationController.text.trim(),
      );

      if (!mounted) return;

      setState(() {
        _schemes = schemes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'Unable to find schemes. Check the server.',
      );
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _ageController.dispose();
    _situationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAF9),
      appBar: AppBar(
        title: Text(
          'Smart Scheme Finder',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            _introCard(),

            const SizedBox(height: 24),

            Text(
              'Patient Details',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 14),

            TextField(
              controller: _ageController,
              keyboardType:
                  TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Age',
                prefixIcon: const Icon(
                  Icons.cake_outlined,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 14),

            DropdownButtonFormField<String>(
              initialValue: _gender,
              decoration: InputDecoration(
                labelText: 'Gender',
                prefixIcon: const Icon(
                  Icons.person_outline,
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
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

            const SizedBox(height: 14),

            TextField(
              controller:
                  _situationController,
              maxLines: 5,
              decoration: InputDecoration(
                labelText:
                    'Describe health situation',
                hintText:
                    'Example: pregnant woman needs information about available health benefits',
                alignLabelWithHint: true,
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(
                    bottom: 85,
                  ),
                  child: Icon(
                    Icons.description_outlined,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),

            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton.icon(
                onPressed:
                    _loading
                        ? null
                        : _findSchemes,
                icon: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome,
                      ),
                label: Text(
                  _loading
                      ? 'CHECKING...'
                      : 'FIND ELIGIBLE SCHEMES',
                ),
                style:
                    FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF087F73),
                ),
              ),
            ),

            if (_schemes.isNotEmpty) ...[
              const SizedBox(height: 30),

              Text(
                'Possible Matches',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 12),

              ..._schemes.map(
                (scheme) =>
                    _schemeCard(scheme),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _introCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE5F5F2),
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_outlined,
            size: 40,
            color: Color(0xFF087F73),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Find government health benefits and '
              'understand the next steps for the patient.',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _schemeCard(
    HealthScheme scheme,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFDDE8E5),
        ),
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFE5F5F2),
                  borderRadius:
                      BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.verified_outlined,
                  color:
                      Color(0xFF087F73),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  scheme.name,
                  style: GoogleFonts.inter(
                    fontSize: 17,
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            scheme.description,
            style: const TextStyle(
              height: 1.5,
            ),
          ),

          const SizedBox(height: 16),

          _section(
            'Potential Eligibility',
            scheme.eligibility,
          ),

          _section(
            'Required Documents',
            scheme.documents.join('\n• '),
          ),

          _section(
            'What To Do Next',
            scheme.steps.join('\n'),
          ),

          const SizedBox(height: 8),

          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius:
                  BorderRadius.circular(10),
            ),
            child: const Text(
              'Eligibility shown is a preliminary AI-assisted '
              'match. Verify with the official scheme authority.',
              style: TextStyle(
                fontSize: 11,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    String value,
  ) {
    return Padding(
      padding:
          const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: const TextStyle(
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}
