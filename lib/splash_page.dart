import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'onboarding_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // ✨ Initialize fade animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();

    // 🚀 Start splash sequence
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    await Future.delayed(const Duration(seconds: 2));
    await _checkUserStatus();
  }

  /// 🔍 Check if user already exists in Firestore
  Future<void> _checkUserStatus() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc('local_user')
          .get();

      if (!mounted) return;

      final bool isExistingUser =
          userDoc.exists && (userDoc.data()?['name'] as String?)?.isNotEmpty == true;

      if (isExistingUser) {
        // ✅ Existing user → Go to HomePage
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        // 🆕 First-time user → Go to OnboardingPage
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const OnboardingPage()),
        );
      }
    } catch (e, st) {
      // ⚠️ Fallback if Firestore check fails
      debugPrint('Splash: failed to check user status: $e\n$st');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking user data. Starting onboarding...')),
      );

      // Default to onboarding
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
    const Color splashBackgroundColor = Color(0xFFE8F0E8);
    const Color logoColor = Color(0xFF2C9C6C);

    return Scaffold(
      backgroundColor: splashBackgroundColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: logoColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.trending_up,
                      size: 64,
                      color: logoColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'FinTrackU',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: logoColor,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
