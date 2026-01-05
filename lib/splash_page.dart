// splash_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'onboarding_page.dart';
import 'home_page.dart'; // MainShell

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Wait 2 seconds
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      // User already logged in → Go Home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainShell()),
      );
    } else {
      // User NOT logged in → Go Onboarding
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/myapp.png',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 16),
              Image.asset(
                'assets/images/opening.png',
                fit: BoxFit.contain,
              ),
            ],
          ),
        ),
      ),
    );
  }
}