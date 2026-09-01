import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import 'phc_patient_screen.dart';
import '../../services/patient_service.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState
    extends State<QrScannerScreen> {
  final MobileScannerController controller =
      MobileScannerController();

  bool scanned = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  Future<void> _handleScan(
    BarcodeCapture capture,
  ) async {
    if (scanned) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;

      if (value == null || value.isEmpty) {
        continue;
      }

      if (!value.startsWith(
        'vission-health://patient/',
      )) {
        continue;
      }

      scanned = true;

      controller.stop();

      final patientId = value
          .replaceFirst(
            'vission-health://patient/',
            '',
          );

      final patientService =
          PatientService();

      final patient =
          await patientService.getPatient(
        patientId,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PhcPatientScreen(
            patientId: patientId,
            patient: patient ?? const {},
          ),
        ),
      );

      break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text(
          'Scan Health Passport',
        ),

        backgroundColor: Colors.black,
        foregroundColor: Colors.white,

        actions: [
          IconButton(
            onPressed: () {
              controller.toggleTorch();
            },
            icon: const Icon(
              Icons.flash_on,
            ),
          ),
        ],
      ),

      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleScan,
          ),

          Center(
            child: Container(
              width: 260,
              height: 260,

              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.white,
                  width: 3,
                ),

                borderRadius:
                    BorderRadius.circular(20),
              ),
            ),
          ),

          Positioned(
            left: 30,
            right: 30,
            bottom: 50,

            child: Container(
              padding:
                  const EdgeInsets.all(16),

              decoration: BoxDecoration(
                color: Colors.black
                    .withValues(alpha: .75),

                borderRadius:
                    BorderRadius.circular(16),
              ),

              child: const Column(
                children: [
                  Icon(
                    Icons.qr_code_scanner,
                    color: Colors.white,
                    size: 30,
                  ),

                  SizedBox(height: 8),

                  Text(
                    'Align the patient QR code inside the frame',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),

                  SizedBox(height: 5),

                  Text(
                    'Only authorized PHC personnel should access patient information.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
