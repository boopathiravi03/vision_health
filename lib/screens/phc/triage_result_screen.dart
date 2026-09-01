import 'package:flutter/material.dart';

import '../../models/triage_result.dart';
import '../../services/triage_ai_service.dart';
import '../../services/triage_engine.dart';

class TriageResultScreen extends StatefulWidget {
  final String patientId;
  final Map<String, dynamic> patient;

  const TriageResultScreen({
    super.key,
    required this.patientId,
    required this.patient,
  });

  @override
  State<TriageResultScreen> createState() =>
      _TriageResultScreenState();
}

class _TriageResultScreenState
    extends State<TriageResultScreen> {
  TriageResult? result;
  Map<String, dynamic>? aiExplanation;
  bool loadingExplanation = false;

  @override
  void initState() {
    super.initState();
    runAssessment();
  }

  Future<void> generateExplanation() async {
    if (result == null) {
      return;
    }

    setState(() {
      loadingExplanation = true;
    });

    try {
      final rawSymptoms =
          widget.patient['symptoms'];

      List<String> symptoms = [];

      if (rawSymptoms is List) {
        symptoms = rawSymptoms
            .map((e) => e.toString())
            .toList();
      } else if (rawSymptoms != null) {
        symptoms = [rawSymptoms.toString()];
      }

      final explanation =
          await TriageAiService.getExplanation(
        patientName:
            widget.patient['name']
                    ?.toString() ??
                'Patient',
        age: int.tryParse(
              widget.patient['age']
                      ?.toString() ??
                  '',
            ) ??
            0,
        symptoms: symptoms,
        riskLevel: result!.riskLabel,
        action: result!.action,
        language: 'English',
      );

      if (!mounted) {
        return;
      }

      setState(() {
        aiExplanation = explanation;
        loadingExplanation = false;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        aiExplanation = {
          'explanation':
              'Unable to connect to the AI service.',
        };
        loadingExplanation = false;
      });
    }
  }

  void runAssessment() {
    final age = int.tryParse(
          widget.patient['age']?.toString() ?? '',
        ) ??
        0;

    final rawSymptoms =
        widget.patient['symptoms'];

    List<String> symptoms = [];

    if (rawSymptoms is List) {
      symptoms = rawSymptoms
          .map((e) => e.toString())
          .toList();
    } else if (rawSymptoms != null) {
      symptoms = [rawSymptoms.toString()];
    }

    final symptomText =
        symptoms.join(' ').toLowerCase();

    final assessment =
        TriageEngine.assess(
      age: age,
      symptoms: symptoms,
      difficultyBreathing:
          symptomText.contains('difficulty breathing') ||
              symptomText.contains('breathing difficulty'),
      unconscious:
          symptomText.contains('unconscious'),
      severeBleeding:
          symptomText.contains('severe bleeding'),
      chestPain:
          symptomText.contains('chest pain'),
      seizure:
          symptomText.contains('seizure'),
      severeDehydration:
          symptomText.contains('severe dehydration'),
    );

    setState(() {
      result = assessment;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (result == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final triage = result!;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI-Assisted Triage',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Patient',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 4),

            Text(
              widget.patient['name']
                      ?.toString() ??
                  'Unknown',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            _riskCard(triage),

            const SizedBox(height: 20),

            _section(
              'Recommended Action',
              triage.action,
              Icons.medical_services,
            ),

            const SizedBox(height: 15),

            _section(
              'Assessment',
              triage.reason,
              Icons.analytics_outlined,
            ),

            if (triage.redFlags.isNotEmpty) ...[
              const SizedBox(height: 20),

              const Text(
                'Detected Warning Signs',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              ...triage.redFlags.map(
                (flag) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.warning_amber_rounded,
                  ),
                  title: Text(flag),
                ),
              ),
            ],

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),

              decoration: BoxDecoration(
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),

              child: const Text(
                'This tool provides decision support '
                'for frontline workers. It does not '
                'replace assessment by a qualified '
                'healthcare professional.',
                style: TextStyle(
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: loadingExplanation
                    ? null
                    : generateExplanation,
                icon: const Icon(
                  Icons.auto_awesome,
                ),
                label: Text(
                  loadingExplanation
                      ? 'GENERATING...'
                      : 'GET AI EXPLANATION',
                ),
              ),
            ),

            if (aiExplanation != null) ...[
              const SizedBox(height: 20),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,

                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.auto_awesome,
                          ),

                          SizedBox(width: 8),

                          Text(
                            'AI Explanation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      Text(
                        aiExplanation!['explanation']
                                ?.toString() ??
                            '',
                        style: const TextStyle(
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _riskCard(TriageResult result) {
    IconData icon;

    switch (result.riskLevel) {
      case RiskLevel.low:
        icon = Icons.check_circle;

      case RiskLevel.moderate:
        icon = Icons.warning_amber;

      case RiskLevel.high:
        icon = Icons.error;
    }

    Color color;

    switch (result.riskLevel) {
      case RiskLevel.low:
        color = const Color(0xFF087F73);

      case RiskLevel.moderate:
        color = Colors.orange;

      case RiskLevel.high:
        color = Colors.red;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),

      decoration: BoxDecoration(
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color: color,
          width: 2,
        ),
      ),

      child: Column(
        children: [
          Icon(
            icon,
            size: 60,
            color: color,
          ),

          const SizedBox(height: 12),

          Text(
            result.riskLabel,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            result.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(
    String title,
    String content,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Row(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Icon(icon),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  Text(content),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
