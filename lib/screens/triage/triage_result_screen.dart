import 'package:flutter/material.dart';

class TriageResultScreen extends StatelessWidget {
  final String patientName;
  final int age;
  final List<String> symptoms;
  final String riskLevel;
  final String action;
  final String explanation;

  const TriageResultScreen({
    super.key,
    required this.patientName,
    required this.age,
    required this.symptoms,
    required this.riskLevel,
    required this.action,
    required this.explanation,
  });

  Color _riskColor() {
    final risk = riskLevel.toUpperCase();

    if (risk.contains('HIGH')) {
      return Colors.red;
    }

    if (risk.contains('MODERATE')) {
      return Colors.orange;
    }

    return Colors.green;
  }

  IconData _riskIcon() {
    final risk = riskLevel.toUpperCase();

    if (risk.contains('HIGH')) {
      return Icons.warning_rounded;
    }

    if (risk.contains('MODERATE')) {
      return Icons.priority_high_rounded;
    }

    return Icons.check_circle_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('AI Triage'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _patientCard(),

            const SizedBox(height: 16),

            _riskCard(riskColor),

            const SizedBox(height: 16),

            _explanationCard(),

            const SizedBox(height: 16),

            _actionCard(riskColor),

            const SizedBox(height: 16),

            _disclaimer(),
          ],
        ),
      ),
    );
  }

  Widget _patientCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Patient',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            patientName,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Age: $age',
            style: const TextStyle(
              fontSize: 15,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            'Symptoms',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            symptoms.isEmpty
                ? 'No symptoms recorded'
                : symptoms.join(', '),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskCard(Color riskColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: riskColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: riskColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        children: [
          Icon(
            _riskIcon(),
            size: 55,
            color: riskColor,
          ),

          const SizedBox(height: 10),

          const Text(
            'AI TRIAGE RESULT',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            riskLevel,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 27,
              fontWeight: FontWeight.bold,
              color: riskColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _explanationCard() {
    return _sectionCard(
      title: 'AI Explanation',
      icon: Icons.auto_awesome,
      child: Text(
        explanation,
        style: const TextStyle(
          fontSize: 15,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _actionCard(Color riskColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.local_hospital_rounded,
                color: riskColor,
              ),
              const SizedBox(width: 8),
              const Text(
                'Recommended Action',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            action,
            style: const TextStyle(
              fontSize: 16,
              height: 1.5,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: const Color(0xFF087F73),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          child,
        ],
      ),
    );
  }

  Widget _disclaimer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'AI triage is a screening aid, not a medical diagnosis. '
        'Clinical assessment should be performed by a qualified healthcare professional.',
        style: TextStyle(
          fontSize: 12,
          height: 1.5,
        ),
      ),
    );
  }
}
