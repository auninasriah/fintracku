// onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // <- ditambah

import 'login_page.dart';

// Screens
import 'onboarding_screens/on_page_intro.dart';
import 'onboarding_screens/on_page_income_goal.dart';
import 'onboarding_screens/on_page_settings.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _page = 0;

  final TextEditingController _incomeCtrl = TextEditingController();
  String? _goal;
  bool _notifications = true;
  String _theme = "light";

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _incomeCtrl.dispose();
    super.dispose();
  }

  // BUILD onboarding payload
  Map<String, dynamic> _buildPayload() {
    return <String, dynamic>{
      'monthly_income': double.tryParse(_incomeCtrl.text) ?? 0.0,
      'goal': _goal,
      'notifications_enabled': _notifications,
      'theme': _theme,
      'created_at': DateTime.now().toIso8601String(),
    };
  }

  // HANDLE FINISH
  Future<void> _finishOnboarding() async {
    final user = FirebaseAuth.instance.currentUser;
    final payload = _buildPayload();

    if (user != null) {
      // Save onboarding payload to Firestore for the logged-in user (merge)
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(payload, SetOptions(merge: true));
      } catch (e) {
        // optional: show error but still continue to home
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Gagal simpan data onboarding: $e")),
          );
        }
      }

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // User not logged in — forward the onboarding payload to LoginPage
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage(initialOnboardingData: payload)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) {
                  setState(() => _page = index);
                },
                children: [
                  const OnPageIntro(),
                  OnPageIncomeGoal(
                    incomeController: _incomeCtrl,
                    currentGoal: _goal,
                    onGoalSelected: (g) => setState(() => _goal = g),
                  ),
                  OnPageSettings(
                    notifications: _notifications,
                    theme: _theme,
                    onToggleNotifications: (b) =>
                        setState(() => _notifications = b),
                    onThemeChange: (t) => setState(() => _theme = t),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            SmoothPageIndicator(
              controller: _controller,
              count: 3,
              effect: const WormEffect(
                dotHeight: 10,
                dotWidth: 10,
                spacing: 14,
                activeDotColor: Colors.blueAccent,
              ),
            ),

            const SizedBox(height: 20),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (_page == 2) {
                    _finishOnboarding();
                  } else {
                    _controller.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  }
                },
                child: Text(
                  _page == 2 ? "Start" : "Next",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontSize: 18,
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
