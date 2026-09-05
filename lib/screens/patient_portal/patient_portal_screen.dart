import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'patient_ai_assistant_screen.dart';
import 'patient_ai_scanner_screen.dart';
import 'government_benefits_screen.dart';
import 'medicine_scanner_screen.dart';
import 'nearby_phc_screen.dart';
import 'patient_care_instructions_screen.dart';
import 'patient_health_records_screen.dart';
import '../patient/health_passport_screen.dart';
import '../qr/qr_scanner_screen.dart';
import '../../services/auth_service.dart';
import '../../services/patient_service.dart';

class PatientPortalScreen extends StatefulWidget {
  final String patientId;
  final String patientName;

  const PatientPortalScreen({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<PatientPortalScreen> createState() => _PatientPortalScreenState();
}

class _PatientPortalScreenState extends State<PatientPortalScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(
        title: Text(
          '${widget.patientName}\'s Portal',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout_rounded),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _welcomeCard(widget.patientName),

            const SizedBox(height: 24),

            const Text(
              'AI Health Support',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _featureCard(
              context,
              icon: Icons.record_voice_over_rounded,
              title: 'Talk to AI',
              subtitle:
                  'Speak in your language and hear simple health guidance.',
              color: const Color(0xFF087F73),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientAiAssistantScreen(),
                  ),
                );
              },
            ),

            _featureCard(
              context,
              icon: Icons.camera_alt_rounded,
              title: 'Scan Medicine / Report',
              subtitle: 'Take a photo and let AI explain what is visible.',
              color: const Color(0xFF1565C0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const PatientAiScannerScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'My Health',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _featureCard(
              context,
              icon: Icons.qr_code_2_rounded,
              title: 'Health Passport',
              subtitle: 'View your digital health passport and QR record.',
              color: const Color(0xFF087F73),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HealthPassportScreen(patientId: widget.patientId),
                  ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PatientHealthRecordsScreen(patientId: widget.patientId),
                  ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PatientCareInstructionsScreen(patientId: widget.patientId),
                  ),
                );
              },
            ),

            const SizedBox(height: 18),

            const Text(
              'Benefits & Services',
              style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            _featureCard(
              context,
              icon: Icons.account_balance_rounded,
              title: 'Government Schemes',
              subtitle: 'Check schemes and benefits that may apply to you.',
              color: const Color(0xFF087F73),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GovernmentBenefitsScreen(),
                  ),
                );
              },
            ),

            _featureCard(
              context,
              icon: Icons.medication_outlined,
              title: 'Scan Medicine',
              subtitle:
                  'Forgot what a tablet is? Scan the package and get a simple explanation.',
              color: const Color(0xFF1565C0),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MedicineScannerScreen(),
                  ),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => NearbyPhcScreen(patientId: widget.patientId),
                  ),
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

  Widget _welcomeCard(String patientName) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F6F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFD3ECE7)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.person_rounded,
              size: 34,
              color: Color(0xFF087F73),
            ),
          ),

          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $patientName',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF073B36),
                  ),
                ),

                const SizedBox(height: 5),

                const Text(
                  'Your health information and AI support are available here.',
                  style: TextStyle(color: Colors.black54, height: 1.4),
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
        border: Border.all(color: const Color(0xFFE0E9E6)),
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
          child: Icon(icon, color: color, size: 29),
        ),

        title: Text(
          title,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: Text(
            subtitle,
            style: const TextStyle(color: Colors.grey, height: 1.35),
          ),
        ),

        trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
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
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: Colors.orange),

          SizedBox(width: 12),

          Expanded(
            child: Text(
              'Vission Health provides AI-assisted information only. '
              'It does not replace a doctor or healthcare professional. '
              'For emergencies, contact your local emergency service or visit a healthcare facility.',
              style: TextStyle(fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    if (!context.mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => const PatientPortalAccessScreen(),
      ),
      (route) => false,
    );
  }
}

class PatientPortalAccessScreen extends StatefulWidget {
  const PatientPortalAccessScreen({super.key});

  @override
  State<PatientPortalAccessScreen> createState() =>
      _PatientPortalAccessScreenState();
}

class _PatientPortalAccessScreenState extends State<PatientPortalAccessScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final PatientService _patientService = PatientService();
  bool _loading = false;
  bool _obscurePassword = true;

  Future<void> _openPortal() async {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter your email and password.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final credential = await _authService.signIn(
        email: _emailController.text,
        password: _passwordController.text,
      );
      final user = credential.user;
      if (user == null) {
        throw StateError('No authenticated user was returned.');
      }
      final isPatient = await _authService.hasRole(user.uid, 'patient');
      final patient = isPatient
          ? await _patientService.getPatientForAuthUid(user.uid)
          : null;
      if (!mounted) return;
      if (patient == null) {
        await _authService.signOut();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('This login is not linked to a patient record.'),
          ),
        );
        return;
      }
      final name = patient['name']?.toString().trim();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PatientPortalScreen(
            patientId: patient['id'].toString(),
            patientName: name?.isNotEmpty == true ? name! : 'Patient',
          ),
        ),
      );
    } on FirebaseAuthException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.code == 'invalid-credential'
                ? 'Invalid email or password.'
                : 'Unable to sign in. Please try again.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the patient record.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _scanQrToLogin() async {
    if (_loading) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QrScannerScreen(
          onScanned: (patientId) async {
            if (!mounted) return;
            Navigator.pop(context);
            await _openPortalWithPatientId(patientId);
          },
        ),
      ),
    );
  }

  Future<void> _openPortalWithPatientId(String patientId) async {
    setState(() => _loading = true);
    try {
      final patient = await _patientService.getPatient(patientId);
      if (!mounted) return;
      if (patient == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No patient record found for this QR code.'),
          ),
        );
        return;
      }
      final name = patient['name']?.toString().trim();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PatientPortalScreen(
            patientId: patientId,
            patientName: name?.isNotEmpty == true ? name! : 'Patient',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the patient record.')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F8),
      appBar: AppBar(title: const Text('Patient Portal')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.health_and_safety_outlined,
                  size: 58,
                  color: Color(0xFF087F73),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Patient login',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to access your own health passport, records and care instructions.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility
                            : Icons.visibility_off,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  onSubmitted: (_) => _openPortal(),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _openPortal,
                    child: Text(_loading ? 'SIGNING IN...' : 'LOGIN'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _scanQrToLogin,
                    icon: const Icon(Icons.qr_code_scanner_outlined),
                    label: const Text('SCAN QR TO LOGIN'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
