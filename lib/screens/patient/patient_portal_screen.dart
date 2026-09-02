import 'package:flutter/material.dart';

class PatientPortalScreen extends StatelessWidget {
  const PatientPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: const Text('Patient Portal'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F6F3),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.person_outline,
                  size: 60,
                  color: Color(0xFF087F73),
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'Patient Access',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF073B36),
                ),
              ),

              const SizedBox(height: 12),

              const Text(
                'Your ASHA worker can register you in the system. '
                'Once registered, you can view your Health Passport and QR record here.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              FilledButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Patient lookup will be connected next.',
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.search),
                label: const Text('FIND MY RECORD'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
