import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../models/health_scheme.dart';

class QrPassportScreen extends StatelessWidget {
  final HealthScheme scheme;
  final String patientName;
  final String patientId;

  const QrPassportScreen({
    super.key,
    required this.scheme,
    required this.patientName,
    required this.patientId,
  });

  @override
  Widget build(BuildContext context) {
    final String reference =
        'VH-$patientId-${scheme.id}';

    final String qrData =
        'VISSION_HEALTH|'
        'REF:$reference|'
        'SCHEME:${scheme.id}';

    return Scaffold(
      backgroundColor:
          const Color(0xFFF7FAF9),

      appBar: AppBar(
        title: const Text(
          'Benefit Passport',
        ),
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),

        child: Column(
          children: [
            _header(),

            const SizedBox(height: 20),

            _qrCard(qrData),

            const SizedBox(height: 20),

            _detailsCard(reference),

            const SizedBox(height: 20),

            _instructionCard(),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'QR passport is ready to share.',
                      ),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.share,
                ),

                label: const Text(
                  'SHARE PASSPORT',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Column(
      children: [
        Container(
          padding:
              const EdgeInsets.all(14),

          decoration: BoxDecoration(
            color:
                const Color(0xFFE8F6F3),
            shape: BoxShape.circle,
          ),

          child: const Icon(
            Icons.verified,
            size: 42,
            color:
                Color(0xFF087F73),
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Vission Health',
          style: TextStyle(
            fontSize: 24,
            fontWeight:
                FontWeight.bold,
            color:
                Color(0xFF087F73),
          ),
        ),

        const SizedBox(height: 5),

        const Text(
          'Digital Benefit Passport',
          style: TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _qrCard(String qrData) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(24),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(22),

        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),

      child: Column(
        children: [
          const Text(
            'SCAN AT PHC',
            style: TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.bold,
              letterSpacing: 1,
              color:
                  Color(0xFF087F73),
            ),
          ),

          const SizedBox(height: 18),

          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: 220,
          ),

          const SizedBox(height: 14),

          const Text(
            'Show this QR code at the\nparticipating health facility.',
            textAlign:
                TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _detailsCard(
    String reference,
  ) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),

        border: Border.all(
          color:
              const Color(0xFFE0E9E6),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          const Text(
            'Benefit Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight:
                  FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          _row(
            'Patient',
            patientName,
          ),

          _row(
            'Scheme',
            scheme.name,
          ),

          _row(
            'Category',
            scheme.category,
          ),

          _row(
            'Reference',
            reference,
          ),
        ],
      ),
    );
  }

  Widget _row(
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
          SizedBox(
            width: 85,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),

          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _instructionCard() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color:
            const Color(0xFFE8F6F3),
        borderRadius:
            BorderRadius.circular(18),
      ),

      child: const Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Icon(
            Icons.info_outline,
            color:
                Color(0xFF087F73),
          ),

          SizedBox(width: 10),

          Expanded(
            child: Text(
              'Carry the required documents listed in the benefit section and show this QR reference at the health facility.',
              style: TextStyle(
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
