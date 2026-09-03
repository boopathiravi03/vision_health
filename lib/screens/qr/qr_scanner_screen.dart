import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../patient/health_passport_screen.dart';

class QrScannerScreen extends StatefulWidget {
  final void Function(String patientId)? onScanned;

  const QrScannerScreen({super.key, this.onScanned});

  @override
  State<QrScannerScreen> createState() =>
      _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool scanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Health Passport'),
      ),
      body: MobileScanner(
        onDetect: (capture) {
          if (scanned) return;

          final barcode = capture.barcodes.firstOrNull;
          final patientId = barcode?.rawValue;

          if (patientId == null || patientId.isEmpty) {
            return;
          }

          scanned = true;

          if (widget.onScanned != null) {
            widget.onScanned!(patientId);
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => HealthPassportScreen(
                patientId: patientId,
              ),
            ),
          );
        },
      ),
    );
  }
}
