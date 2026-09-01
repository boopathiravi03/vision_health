import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

class ReferralQRScreen extends StatelessWidget {
  final String referralId;
  final String patientName;
  final String riskLevel;

  const ReferralQRScreen({
    super.key,
    required this.referralId,
    required this.patientName,
    required this.riskLevel,
  });

  Color get riskColor {
    switch (riskLevel) {
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
        title: const Text('Referral Created'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 15),

            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Colors.green,
                size: 45,
              ),
            ),

            const SizedBox(height: 15),

            Text(
              'Referral Created',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Show this QR code at the PHC',
              style: GoogleFonts.inter(
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 30),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFE3EAE8),
                ),
              ),
              child: Column(
                children: [
                  Text(
                    patientName.isEmpty
                        ? 'Patient'
                        : patientName,
                    style: GoogleFonts.inter(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: riskColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Text(
                      '$riskLevel PRIORITY',
                      style: GoogleFonts.inter(
                        color: riskColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  QrImageView(
                    data: referralId,
                    version: QrVersions.auto,
                    size: 230,
                  ),

                  const SizedBox(height: 18),

                  Text(
                    'Referral ID',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),

                  const SizedBox(height: 5),

                  SelectableText(
                    referralId,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6F3),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.info_outline_rounded,
                    color: Color(0xFF087F73),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'The PHC can scan this code to retrieve the referral record.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: () {
                  Navigator.popUntil(
                    context,
                    (route) => route.isFirst,
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor:
                      const Color(0xFF087F73),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'BACK TO DASHBOARD',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
