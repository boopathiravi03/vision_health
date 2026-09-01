import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'screens/phc/phc_dashboard_screen.dart';
import 'services/voice_service.dart';
import 'services/ai_api_service.dart';
import 'services/firestore_service.dart';
import 'services/local_storage_service.dart';
import 'services/app_sync_manager.dart';
import 'models/health_analysis.dart';
import 'screens/ai_analysis/analysis_screen.dart';
import 'logic/risk_engine.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await LocalStorageService.initialize();

  final syncManager = AppSyncManager();
  syncManager.start();

  runApp(const VissionHealthApp());
}

class VissionHealthApp extends StatelessWidget {
  const VissionHealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vission Health',
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFF7FAF9),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F73),
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const SplashScreen(),
    );
  }
}

// ------------------------------------------------------------
// SPLASH SCREEN
// ------------------------------------------------------------

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const RoleSelectionScreen(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF087F73),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                height: 90,
                width: 90,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(
                  Icons.health_and_safety_rounded,
                  size: 52,
                  color: Color(0xFF087F73),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'VISSION HEALTH',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 27,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                'AI-powered healthcare for every village',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 40),

              const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// ROLE SELECTION
// ------------------------------------------------------------

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Spacer(),

              Center(
                child: Container(
                  height: 82,
                  width: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F4F1),
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    color: Color(0xFF087F73),
                    size: 46,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Center(
                child: Text(
                  'Welcome to Vission Health',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF102A2A),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Center(
                child: Text(
                  'Choose how you want to continue',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              const SizedBox(height: 38),

              _RoleCard(
                icon: Icons.medical_services_rounded,
                title: 'ASHA Worker',
                subtitle:
                    'Manage patients, visits, referrals and follow-ups',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LoginScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _RoleCard(
                icon: Icons.person_rounded,
                title: 'Patient',
                subtitle:
                    'Get healthcare information and assistance',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Patient mode will be added in the next stage.',
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              _RoleCard(
                icon: Icons.local_hospital_rounded,
                title: 'PHC Staff',
                subtitle:
                    'Monitor patients, review urgent cases and follow-ups',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const PhcDashboardScreen(),
                    ),
                  );
                },
              ),

              const Spacer(),

              Center(
                child: Text(
                  'தமிழ்  •  English  •  हिंदी',
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFFE3EAE8),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 58,
              width: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F4F1),
                borderRadius: BorderRadius.circular(17),
              ),
              child: Icon(
                icon,
                color: const Color(0xFF087F73),
                size: 30,
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF102A2A),
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Color(0xFF087F73),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// NEW PATIENT VISIT
// ------------------------------------------------------------

class NewVisitScreen extends StatefulWidget {
  const NewVisitScreen({super.key});

  @override
  State<NewVisitScreen> createState() => _NewVisitScreenState();
}

class _NewVisitScreenState extends State<NewVisitScreen> {
  final nameController = TextEditingController();
  final ageController = TextEditingController();

  final VoiceService _voiceService = VoiceService();
  final AIApiService _aiApiService = AIApiService();
  final FirestoreService _firestoreService = FirestoreService();

  String selectedLanguage = 'தமிழ்';
  String selectedGender = 'Female';

  String transcript = '';

  bool isListening = false;
  bool isProcessing = false;

  @override
  void dispose() {
    nameController.dispose();
    ageController.dispose();
    super.dispose();
  }

  Future<void> _toggleVoice() async {
    if (isListening) {
      await _voiceService.stopListening();

      setState(() {
        isListening = false;
      });

      return;
    }

    String locale = 'ta_IN';

    if (selectedLanguage == 'English') {
      locale = 'en_US';
    }

    setState(() {
      isListening = true;
      transcript = '';
    });

    await _voiceService.startListening(
      localeId: locale,
      onResult: (text) {
        if (!mounted) return;

        setState(() {
          transcript = text;
        });
      },
    );
  }

  Future<void> _analyzeWithAI() async {
    if (transcript.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please record the patient symptoms first.',
          ),
        ),
      );
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final age = int.tryParse(
            ageController.text.trim(),
          ) ??
          0;

      final result = await _aiApiService.analyze(
        patientName: nameController.text.trim(),
        age: age,
        gender: selectedGender,
        language: selectedLanguage,
        transcript: transcript,
      );

      final risk = RiskEngine.assess(
        symptoms: result.symptoms,
        severity: result.severity,
        duration: result.duration,
      );

      final analysis = HealthAnalysis(
        patientName: nameController.text.trim(),
        age: age,
        gender: selectedGender,
        language: selectedLanguage,
        transcript: transcript,
        symptoms: result.symptoms,
        duration: result.duration,
        severity: result.severity,
        dangerSigns: risk.dangerSigns,
        riskLevel: risk.level,
        recommendedAction: risk.action,
      );

      await _firestoreService.savePatientVisit(
        analysis,
      );

      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisScreen(
            analysis: analysis,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isProcessing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'AI analysis failed. Please check your connection.',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Patient Visit',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 5, 20, 30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Patient Information',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),

            const SizedBox(height: 6),

            Text(
              'Enter basic details or use voice input.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),

            const SizedBox(height: 25),

            _InputLabel(label: 'Patient Name'),

            const SizedBox(height: 8),

            TextField(
              controller: nameController,
              decoration: _inputDecoration(
                hint: 'Enter patient name',
                icon: Icons.person_outline_rounded,
              ),
            ),

            const SizedBox(height: 18),

            _InputLabel(label: 'Age'),

            const SizedBox(height: 8),

            TextField(
              controller: ageController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                hint: 'Enter age',
                icon: Icons.calendar_today_outlined,
              ),
            ),

            const SizedBox(height: 18),

            _InputLabel(label: 'Gender'),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: selectedGender,
              decoration: _inputDecoration(
                hint: 'Select gender',
                icon: Icons.people_outline_rounded,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'Female',
                  child: Text('Female'),
                ),
                DropdownMenuItem(
                  value: 'Male',
                  child: Text('Male'),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedGender = value;
                  });
                }
              },
            ),

            const SizedBox(height: 18),

            _InputLabel(label: 'Preferred Language'),

            const SizedBox(height: 8),

            DropdownButtonFormField<String>(
              initialValue: selectedLanguage,
              decoration: _inputDecoration(
                hint: 'Select language',
                icon: Icons.language_rounded,
              ),
              items: const [
                DropdownMenuItem(
                  value: 'தமிழ்',
                  child: Text('தமிழ்'),
                ),
                DropdownMenuItem(
                  value: 'English',
                  child: Text('English'),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedLanguage = value;
                  });
                }
              },
            ),

            const SizedBox(height: 30),

            Center(
              child: Text(
                'VOICE-FIRST HEALTH RECORD',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                  color: const Color(0xFF087F73),
                ),
              ),
            ),

            const SizedBox(height: 15),

            Center(
              child: GestureDetector(
                onTap: _toggleVoice,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: isListening ? 120 : 100,
                  width: isListening ? 120 : 100,
                  decoration: BoxDecoration(
                    color: isListening
                        ? const Color(0xFF087F73)
                        : const Color(0xFFE4F4F1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFBFE5DF),
                      width: 5,
                    ),
                  ),
                  child: Icon(
                    isListening
                        ? Icons.stop_rounded
                        : Icons.mic_rounded,
                    color: isListening
                        ? Colors.white
                        : const Color(0xFF087F73),
                    size: 45,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Center(
              child: Text(
                isListening ? 'Listening...' : 'Tap to speak',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),

            const SizedBox(height: 5),

            Center(
              child: Text(
                'Speak naturally in your preferred language',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),

            if (transcript.isNotEmpty) ...[
              const SizedBox(height: 20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFE2E9E7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.graphic_eq_rounded,
                          color: Color(0xFF087F73),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Voice Transcript',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),

                    Text(
                      transcript,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 25),

            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: isProcessing ? null : _analyzeWithAI,
                icon: isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(
                        Icons.auto_awesome_rounded,
                      ),
                label: Text(
                  isProcessing
                      ? 'ANALYZING...'
                      : 'ANALYZE WITH AI',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                  ),
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
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(
        icon,
        color: const Color(0xFF087F73),
      ),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(
          color: Colors.grey.shade200,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFF087F73),
          width: 1.5,
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  final String label;

  const _InputLabel({
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
