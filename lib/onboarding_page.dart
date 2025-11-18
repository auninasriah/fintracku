// onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';


// --- IMPORT THE NEWLY CREATED PAGE WIDGETS ---
import 'onboarding_screens/on_page_intro.dart';
import 'onboarding_screens/on_page_details.dart';
import 'onboarding_screens/on_page_income_goal.dart';
import 'onboarding_screens/on_page_settings.dart';

// --- VIBRANT BLUE-GREEN THEME COLORS (KEPT IN MAIN FILE) ---
const Color vibrantBlueGreenStart = Color(0xFF005CFF); // Deep vibrant blue
const Color vibrantBlueGreenMid = Color(0xFF00BFFF);   // Sky blue
const Color vibrantBlueGreenEnd = Color(0xFF00FFC0);   // Bright aqua green

// --- MAPPING COLORS TO APP STRUCTURE ---
const Color darkStart = vibrantBlueGreenStart; 
const Color darkEnd = vibrantBlueGreenEnd;     

const Color accentPrimary = Colors.white; 
const Color accentSecondary = Colors.white; 
const Color errorRed = Color(0xFFB00020);

const Color cardBackground = Color(0xFF1E70D0); // A mid-tone vibrant blue for card pop-out
const Color cardBorder = vibrantBlueGreenMid; 
const Color cardTextPrimary = accentPrimary; 
const Color cardTextSecondary = accentSecondary; 
const Color cardIconColor = vibrantBlueGreenMid; 

// --- UPDATED ACTION BUTTON COLORS FOR HIGHER CONTRAST AND NEON GLOW ---
const Color actionGradientStart = Color(0xFF00E0FF); // Brighter Aqua Blue
const Color actionGradientEnd = Color(0xFF6A00FF); // Deep Violet/Purple (High Contrast)
const Color actionButtonGlow = Color(0xAA6A00FF);    // Deeper Violet Glow (lebih jelas)

const Color neonTextStart = Colors.white;
const Color neonTextEnd = Color(0xFF00E0FF); 

const Color cardShadowColor = Color(0x66005CFF);

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // --- STATE AND CONTROLLERS (KEPT IN MAIN FILE) ---
  final PageController _controller = PageController();
  int _currentPage = 0;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();
  final TextEditingController _occupationController = TextEditingController();

  String? _goal;
  bool _notifications = true;
  String _theme = "dark"; 

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light); 
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _incomeController.dispose();
    _occupationController.dispose();
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    super.dispose();
  }
  
  // --- UTILITY SETTERS (USED BY CHILD WIDGETS) ---
  void _setGoal(String? newGoal) {
    setState(() => _goal = newGoal);
  }

  void _setNotifications(bool val) {
    setState(() => _notifications = val);
  }

  void _setTheme(String val) {
    setState(() => _theme = val);
  }

  // --- FIREBASE AND NAVIGATION LOGIC (KEPT IN MAIN FILE) ---
  Future<void> _saveUserData() async {
    if (_incomeController.text.isEmpty || _goal == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in income and select a goal.")),);
      }
      return;
    }

    try {
      // NOTE: Firebase logic remains here
      await FirebaseFirestore.instance.collection('users').doc('local_user').set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'occupation': _occupationController.text.trim(),
        'monthly_income': double.tryParse(_incomeController.text) ?? 0,
        'goal': _goal,
        'notifications_enabled': _notifications,
        'theme': _theme,
        'created_at': DateTime.now(),
      });

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home');

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    }
  }

  void _nextPage() {
    if (_currentPage == 1 && (_nameController.text.isEmpty || _ageController.text.isEmpty || _occupationController.text.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please complete all personal details before continuing.", style: TextStyle(color: accentPrimary)),
        backgroundColor: errorRed,
      ));
      return;
    }

    if (_currentPage < 3) {
      _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    } else {
      _saveUserData();
    }
  }

  void _skip() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  // --- REUSABLE UTILITY WIDGETS (KEPT IN MAIN FILE to manage state/data access) ---
  
  Widget _buildIllustrationArea(IconData icon, String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: cardBackground, 
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cardShadowColor, 
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 80,
            color: cardIconColor, 
          ),
        ),
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: accentPrimary, 
          ),
        ),
      ],
    );
  }

  Widget _buildVibrantCardTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground, 
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: cardTextPrimary, fontWeight: FontWeight.w600), 
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: cardTextSecondary.withOpacity(0.9), fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: cardIconColor), 
          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cardBorder, width: 2), 
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: actionGradientStart, width: 3), 
            borderRadius: BorderRadius.circular(15),
          ),
          fillColor: Colors.transparent, 
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        ),
      ),
    );
  }

  Widget _buildGoalCardForVibrantTheme(String title) {
    final selected = _goal == title;
    return GestureDetector(
      onTap: () => setState(() => _goal = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? actionGradientStart : cardBackground, 
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? actionGradientEnd : cardBorder, 
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cardShadowColor.withOpacity(selected ? 0.6 : 0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Text(
          title,
          style: TextStyle(
              color: selected ? accentPrimary : accentSecondary, 
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }


  // --- MAIN BUILD METHOD (UNCHANGED STRUCTURE) ---
  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkStart, darkEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Skip Button & Top Padding
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: _skip,
                    child: const Text(
                      "Skip",
                      style: TextStyle(
                        color: accentSecondary, 
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Page Content Area - NOW USING EXTERNAL WIDGETS
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    const OnPageIntro(), // Halaman 1
                    
                    OnPageDetails( // Halaman 2: Pass controllers and utility functions
                      nameController: _nameController,
                      ageController: _ageController,
                      occupationController: _occupationController,
                      buildVibrantCardTextField: _buildVibrantCardTextField,
                    ),
                    
                    OnPageIncomeGoal( // Halaman 3: Pass controllers, state, and utility functions
                      incomeController: _incomeController,
                      goal: _goal,
                      setGoal: _setGoal, // Pass the setter function
                      buildIllustrationArea: _buildIllustrationArea,
                      buildVibrantCardTextField: _buildVibrantCardTextField,
                      buildGoalCardForVibrantTheme: _buildGoalCardForVibrantTheme,
                    ),
                    
                    OnPageSettings( // Halaman 4: Pass state and setter functions
                      notifications: _notifications,
                      theme: _theme,
                      setNotifications: _setNotifications,
                      setTheme: _setTheme,
                      buildIllustrationArea: _buildIllustrationArea,
                    ),
                  ],
                ),
              ),

              // Page Indicator
              SmoothPageIndicator(
                controller: _controller,
                count: 4,
                effect: ExpandingDotsEffect(
                  activeDotColor: actionGradientStart, 
                  dotColor: accentSecondary.withOpacity(0.5), 
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
              const SizedBox(height: 20),

              // Action Button (Cyan to Green Gradient)
              Padding(
                padding: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                child: GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [actionGradientStart, actionGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: actionGradientEnd.withOpacity(0.5), 
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _currentPage == 3 ? "Save" : "Next", 
                        style: const TextStyle(
                            color: accentPrimary, 
                            fontSize: 18,
                            fontWeight: FontWeight.w700),
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