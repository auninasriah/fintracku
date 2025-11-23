import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  // ✨ Bright cyan background color based on the requested image
  static const Color brightCyan = Color(0xFF00CFFF); 

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    await Future.delayed(const Duration(seconds: 2));
    await _checkUserStatus();
  }

  Future<void> _checkUserStatus() async {
    try {
      // NOTE: This logic assumes Firebase is correctly initialized elsewhere in the application.
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc('local_user')
          .get();

      if (!mounted) return;

      final bool isExistingUser =
          userDoc.exists && (userDoc.data()?['name'] as String?)?.isNotEmpty == true;

      if (isExistingUser) {
        // Assuming a route named '/home' exists
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
        );
      }
    } catch (e) {
      // Handle potential errors (e.g., Firestore not reachable) by moving to onboarding
      if (!mounted) return;
      // print('Error checking user status: $e'); // Optional: for debugging
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Changed background color to the new bright cyan color
      backgroundColor: brightCyan, 
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              
              Image.asset(
                'assets/images/abc.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 130),

              // --- Gradient Title ---
              ShaderMask(
                shaderCallback: (Rect bounds) {
                  return const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    // Keeping the original gradient colors for the text for contrast
                    colors: [
                      Color(0xFF1D75CF), // deep blue
                      Color(0xFF18C47F), // teal-green
                    ],
                  ).createShader(bounds);
                },
               
              ),
            ],
          ),
        ),
      ),
    );
  }
}