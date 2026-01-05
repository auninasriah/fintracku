// onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'login_page.dart';

// Screens
import 'onboarding_screens/on_page_intro.dart';
import 'onboarding_screens/on_page_income_goal.dart';
import 'onboarding_screens/on_page_settings.dart';

const Color brandStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color brandEnd = Color.fromARGB(255, 126, 91, 182); // Vibrant Purple

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
            SnackBar(content: Text("Failed to save data: $e")),
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

  void _goToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [brandStart, brandEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              /// Page Content
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() => _page = index);
                  },
                  children: [
                    OnPageIntro(
                      onSkip: _page == 0
                          ? () => _goToPage(2)
                          : null,
                    ),
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

              const SizedBox(height: 16),

              /// Smooth Page Indicator
              SmoothPageIndicator(
                controller: _controller,
                count: 3,
                effect: const WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 12,
                  activeDotColor: brandStart,
                  dotColor: Color(0xFFE0E0E0),
                ),
              ),

              const SizedBox(height: 24),

              /// Navigation Buttons - Only show on last page
              if (_page == 2)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: _finishOnboarding,
                          borderRadius: BorderRadius.circular(14),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            child: ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  colors: [brandStart, brandEnd],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ).createShader(bounds);
                              },
                              child: Text(
                                "Get Started",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  fontSize: 16,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
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