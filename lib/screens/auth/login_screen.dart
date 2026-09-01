import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/auth_service.dart';
import '../../screens/dashboard/asha_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final AuthService _authService = AuthService();

  bool isLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (emailController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      _showMessage('Please enter email and password.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      await _authService.signIn(
        email: emailController.text,
        password: passwordController.text,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AshaDashboard(),
        ),
      );
    } on FirebaseAuthException catch (e) {
      String message = 'Login failed.';

      if (e.code == 'invalid-credential') {
        message = 'Invalid email or password.';
      } else if (e.code == 'user-not-found') {
        message = 'No account found with this email.';
      } else if (e.code == 'wrong-password') {
        message = 'Incorrect password.';
      } else if (e.code == 'invalid-email') {
        message = 'Please enter a valid email.';
      }

      _showMessage(message);
    } catch (e) {
      _showMessage('Something went wrong. Please try again.');
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 30),

              Center(
                child: Container(
                  height: 76,
                  width: 76,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE4F4F1),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.health_and_safety_rounded,
                    size: 42,
                    color: Color(0xFF087F73),
                  ),
                ),
              ),

              const SizedBox(height: 25),

              Center(
                child: Text(
                  'ASHA Worker Login',
                  style: GoogleFonts.inter(
                    fontSize: 25,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF102A2A),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              Center(
                child: Text(
                  'Access your Vission Health dashboard',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                  ),
                ),
              ),

              const SizedBox(height: 40),

              Text(
                'Email',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'asha@example.com',
                  prefixIcon: const Icon(
                    Icons.email_outlined,
                    color: Color(0xFF087F73),
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
                ),
              ),

              const SizedBox(height: 20),

              Text(
                'Password',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 8),

              TextField(
                controller: passwordController,
                obscureText: obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Enter password',
                  prefixIcon: const Icon(
                    Icons.lock_outline_rounded,
                    color: Color(0xFF087F73),
                  ),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        obscurePassword = !obscurePassword;
                      });
                    },
                    icon: Icon(
                      obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
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
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton(
                  onPressed: isLoading ? null : _login,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF087F73),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 23,
                          width: 23,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'LOGIN',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 20),

              Center(
                child: Text(
                  'Securely powered by Firebase',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
