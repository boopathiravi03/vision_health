import 'package:flutter/material.dart';

import 'patient_ai_voice_screen.dart';

class PatientPortalScreen extends StatelessWidget {
  const PatientPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text(
          'Patient Portal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(),

            const SizedBox(height: 24),

            const Text(
              'AI Health Support',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _featureCard(
              context,
              icon: Icons.mic_rounded,
              title: 'Talk to Vission AI',
              subtitle:
                  'Speak in your language and get simple health guidance.',
              color: const Color(0xFF087F73),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const PatientAiVoiceScreen(),
                  ),
                );
              },
            ),

            _featureCard(
              context,
              icon: Icons.camera_alt_rounded,
              title: 'Scan Medicine / Report',
              subtitle:
                  'Take a photo and let AI explain what is visible.',
              color: const Color(0xFF1565C0),
              onTap: () {
                _showComingSoon(
                  context,
                  'AI Image Scanner',
                  'Camera-based medicine and report analysis will open here.',
                );
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'My Health',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _featureCard(
              context,
              icon: Icons.qr_code_2_rounded,
              title: 'Health Passport',
              subtitle:
                  'View your digital health passport and QR record.',
              color: const Color(0xFF087F73),
              onTap: () {
                _showComingSoon(
                  context,
                  'Health Passport',
                  'Your digital health passport will open here.',
                );
              },
            ),

            _featureCard(
              context,
              icon: Icons.history_rounded,
              title: 'Health Records',
              subtitle:
                  'View visits, symptoms, risk assessments and follow-ups.',
              color: const Color(0xFF6A1B9A),
              onTap: () {
                _showComingSoon(
                  context,
                  'Health Records',
                  'Your ASHA health records will appear here.',
                );
              },
            ),

            _featureCard(
              context,
              icon: Icons.medical_information_rounded,
              title: 'Care Instructions',
              subtitle:
                  'View instructions and recommendations from your healthcare worker.',
              color: const Color(0xFFE65100),
              onTap: () {
                _showComingSoon(
                  context,
                  'Care Instructions',
                  'Your care instructions will appear here.',
                );
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'Benefits & Services',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _featureCard(
              context,
              icon: Icons.account_balance_rounded,
              title: 'Government Schemes',
              subtitle:
                  'Check schemes and benefits that may apply to you.',
              color: const Color(0xFF087F73),
              onTap: () {
                _showComingSoon(
                  context,
                  'Government Schemes',
                  'Your eligible government health benefits will appear here.',
                );
              },
            ),

            _featureCard(
              context,
              icon: Icons.location_on_rounded,
              title: 'Find Nearby PHC',
              subtitle:
                  'Find nearby Primary Health Centres and healthcare services.',
              color: const Color(0xFF2E7D32),
              onTap: () {
                _showComingSoon(
                  context,
                  'Nearby PHC',
                  'Nearby healthcare centres will appear here.',
                );
              },
            ),

            const SizedBox(height: 24),

            _safetyCard(),
          ],
        ),
      ),
    );
  }

  Widget _welcomeCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD3ECE7),
        ),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person_rounded,
              size: 34,
              color: Color(0xFF087F73),
            ),
          ),

          SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome 👋',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF073B36),
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Your health information and AI support are available here.',
                  style: TextStyle(
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE0E9E6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(14),
        onTap: onTap,

        leading: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(
            icon,
            color: color,
            size: 29,
          ),
        ),

        title: Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(
              color: Colors.grey,
              height: 1.35,
            ),
          ),
        ),

        trailing: const Icon(
          Icons.chevron_right_rounded,
          color: Colors.grey,
        ),
      ),
    );
  }

  Widget _safetyCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.amber.shade200,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Colors.orange,
          ),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Vission Health provides AI-assisted information only. '
              'It does not replace a doctor or healthcare professional. '
              'For emergencies, contact your local emergency service or visit a healthcare facility.',
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(
    BuildContext context,
    String title,
    String message,
  ) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(
            24,
            10,
            24,
            30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: const Color(0xFFE8F6F3),
                child: const Icon(
                  Icons.auto_awesome,
                  color: Color(0xFF087F73),
                  size: 30,
                ),
              ),

              const SizedBox(height: 14),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
