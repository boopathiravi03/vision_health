import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SchemeHospitalsScreen extends StatelessWidget {
  final Map<String, dynamic> scheme;
  final Map<String, dynamic> patient;

  const SchemeHospitalsScreen({
    super.key,
    required this.scheme,
    required this.patient,
  });

  Future<void> _openMap() async {
    final Uri uri = Uri.parse(
      'https://www.openstreetmap.org/search?query=hospitals',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  Future<void> _openDirections() async {
    final Uri uri = Uri.parse(
      'https://www.openstreetmap.org/search?query=hospital',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String schemeName =
        scheme['name']?.toString() ?? 'Health Scheme';

    return Scaffold(
      backgroundColor: const Color(0xffF5FAF9),
      appBar: AppBar(
        backgroundColor: const Color(0xffF5FAF9),
        elevation: 0,
        leading: const BackButton(
          color: Colors.black,
        ),
        title: const Text(
          'Hospitals & Registration',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: ListView(
        children: [
          _mapPreview(),

          _schemeTitle(schemeName),

          _hospitalSection(),

          _registrationSection(),

          _documentsSection(),

          _expectSection(),

          _verificationWarning(),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _mapPreview() {
    return SizedBox(
      height: 300,
      child: Stack(
        children: [
          Container(
            width: double.infinity,
            color: const Color(0xffDCEBE7),
            child: const Center(
              child: Icon(
                Icons.map_outlined,
                size: 75,
                color: Color(0xff00796B),
              ),
            ),
          ),

          Positioned(
            top: 20,
            right: 20,
            child: FloatingActionButton(
              heroTag: 'map',
              backgroundColor: Colors.white,
              foregroundColor: Colors.teal,
              onPressed: _openMap,
              child: const Icon(Icons.my_location),
            ),
          ),

          const Positioned(
            left: 0,
            right: 0,
            bottom: 15,
            child: Center(
              child: Chip(
                avatar: Icon(
                  Icons.location_on,
                  color: Colors.teal,
                ),
                label: Text(
                  'Nearby hospitals',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _schemeTitle(String name) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xffE4F5F2),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.account_balance,
              color: Color(0xff00796B),
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              name,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Find a nearby hospital and understand what to do next.',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hospitalSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Nearby Hospitals',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 12),

          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Color(0xffE4F5F2),
                      child: Icon(
                        Icons.local_hospital,
                        color: Colors.teal,
                      ),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        'Search nearby hospitals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                const Text(
                  'Use the map to find nearby hospitals. '
                  'Before visiting, confirm that the hospital '
                  'supports your selected scheme.',
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),

                const SizedBox(height: 15),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openDirections,
                    icon: const Icon(Icons.directions),
                    label: const Text(
                      'SEARCH HOSPITALS & DIRECTIONS',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _registrationSection() {
    return _infoCard(
      title: 'How to register',
      icon: Icons.app_registration,
      children: [
        _step(
          '1',
          'Check your eligibility through the official scheme portal or authorised centre.',
        ),
        _step(
          '2',
          'Carry your required identification and supporting documents.',
        ),
        _step(
          '3',
          'Visit an authorised hospital or registration centre.',
        ),
        _step(
          '4',
          'Ask the hospital help desk to verify your scheme eligibility.',
        ),
        _step(
          '5',
          'Complete registration/application after eligibility is confirmed.',
        ),
      ],
    );
  }

  Widget _documentsSection() {
    return _infoCard(
      title: 'Documents you may need',
      icon: Icons.description_outlined,
      children: [
        const Text(
          '• Aadhaar / Government ID\n'
          '• Family or eligibility document\n'
          '• Income certificate if applicable\n'
          '• Previous health records if requested\n'
          '• Hospital admission/referral documents if applicable',
          style: TextStyle(
            fontSize: 16,
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _expectSection() {
    return _infoCard(
      title: 'What should you expect?',
      icon: Icons.help_outline,
      children: [
        const Text(
          'At the hospital, the staff will verify your identity '
          'and scheme eligibility. They may ask for documents '
          'and medical records before starting treatment or '
          'registration.',
          style: TextStyle(
            fontSize: 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _verificationWarning() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 10,
      ),
      child: Container(
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
                'Important: A nearby hospital is not automatically '
                'an approved hospital for this scheme. Always '
                'verify scheme availability with the hospital, '
                'PHC or official government authority before visiting.',
                style: TextStyle(
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: Colors.teal,
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _step(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 15,
            backgroundColor: Colors.teal,
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 16,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
