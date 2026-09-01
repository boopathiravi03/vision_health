import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/health_analysis.dart';
import '../../services/referral_service.dart';
import '../referral/referral_qr_screen.dart';

class AnalysisScreen extends StatefulWidget {
  final HealthAnalysis analysis;

  const AnalysisScreen({
    super.key,
    required this.analysis,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  final ReferralService _referralService = ReferralService();

  bool isCreatingReferral = false;

  Color get riskColor {
    switch (widget.analysis.riskLevel) {
      case 'URGENT':
        return Colors.red;
      case 'MEDIUM':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Health Analysis'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.health_and_safety_rounded,
                  size: 45,
                  color: riskColor,
                ),
              ),
            ),

            const SizedBox(height: 18),

            Center(
              child: Text(
                'Analysis Complete',
                style: GoogleFonts.inter(
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),

            const SizedBox(height: 25),

            _sectionTitle('Patient'),

            _infoCard(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  _row('Name', widget.analysis.patientName),
                  _row('Age', '${widget.analysis.age}'),
                  _row('Gender', widget.analysis.gender),
                  _row('Language', widget.analysis.language),
                ],
              ),
            ),

            const SizedBox(height: 20),

            _sectionTitle('Symptoms'),

            _infoCard(
              child: widget.analysis.symptoms.isEmpty
                  ? const Text(
                      'No symptoms confidently identified.',
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.analysis.symptoms
                          .map(
                            (symptom) => Chip(
                              label: Text(symptom),
                            ),
                          )
                          .toList(),
                    ),
            ),

            const SizedBox(height: 20),

            _sectionTitle('Risk Assessment'),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: riskColor.withValues(alpha: 0.25),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    widget.analysis.riskLevel,
                    style: GoogleFonts.inter(
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      color: riskColor,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.analysis.recommendedAction,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (widget.analysis.dangerSigns.isNotEmpty) ...[
              _sectionTitle('Safety Alerts'),

              _infoCard(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: widget.analysis.dangerSigns
                      .map(
                        (item) => Padding(
                          padding:
                              const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.warning_rounded,
                                color: Colors.red,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(item),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF087F73),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'CONTINUE',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),

            if (widget.analysis.riskLevel != 'LOW') ...[
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed:
                      isCreatingReferral ? null : _createReferral,
                  icon: isCreatingReferral
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(
                          Icons.qr_code_rounded,
                        ),
                  label: Text(
                    isCreatingReferral
                        ? 'CREATING REFERRAL...'
                        : 'CREATE PHC REFERRAL',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF087F73),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _createReferral() async {
    setState(() {
      isCreatingReferral = true;
    });

    try {
      final referralId =
          await _referralService.createReferral(
        patientName: widget.analysis.patientName,
        age: widget.analysis.age,
        gender: widget.analysis.gender,
        riskLevel: widget.analysis.riskLevel,
        symptoms: widget.analysis.symptoms,
        reason: widget.analysis.dangerSigns.isEmpty
            ? 'AI-assisted risk assessment'
            : widget.analysis.dangerSigns.join(', '),
        recommendedAction:
            widget.analysis.recommendedAction,
      );

      if (!mounted) return;

      setState(() {
        isCreatingReferral = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReferralQRScreen(
            referralId: referralId,
            patientName: widget.analysis.patientName,
            riskLevel: widget.analysis.riskLevel,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isCreatingReferral = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not create referral: $e',
          ),
        ),
      );
    }
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 17,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _infoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: const Color(0xFFE4EAE8),
        ),
      ),
      child: child,
    );
  }

  Widget _row(String title, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Text(
            value.isEmpty ? 'Not provided' : value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
