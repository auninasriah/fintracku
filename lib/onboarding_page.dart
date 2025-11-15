// onboarding_page.dart

import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';

// --- APPLIED USER'S THEME COLORS ---
const Color primaryBlue = Color(0xFF11355F); // Dark Navy Blue
const Color accentBlue = Color(0xFF234A78); // Medium Blue
const Color lightAccent = Color(0xFF4A72AE); // Lighter accent blue
const Color cardGradientStart = Color(0xFF3B8D99); // Soft Teal (Action Gradient Start)
const Color cardGradientEnd = Color(0xFF4F67B5); // Soft Indigo (Action Gradient End)
const Color actionIconBackground = Color(0xFFE8F5FF); // Very Light Blue for accents/secondary text
const Color cardShadowColor = Color(0x3311355F); // Shadow for primary elements

// --- MAPPING COLORS TO APP STRUCTURE ---

// Background Gradient (Dark Theme Consistency)
const Color darkStart = Color(0xFF0D2C4D); // Slightly darker than primaryBlue
const Color darkEnd = primaryBlue;

// Action Button & Goal Selection Gradient
const Color actionGradientStart = cardGradientStart; // Soft Teal
const Color actionGradientEnd = cardGradientEnd;   // Soft Indigo

// Text and Accent Colors
const Color accentPrimary = Colors.white; // Main text and active elements
const Color accentSecondary = actionIconBackground; // Lighter text/inactive elements
const Color errorRed = Color(0xFFB00020);

// Colors for "popup" style elements (cards, text fields)
const Color cardBackground = accentBlue; // Medium Blue for card pop-out
const Color cardBorder = lightAccent; // Lighter accent blue for borders
const Color cardTextPrimary = accentPrimary; // White text on dark card
const Color cardTextSecondary = accentSecondary; // Very Light Blue text on dark card
const Color cardIconColor = lightAccent; // Lighter accent blue icon color

// Neon Text Gradient (Subtle shining using theme colors, no harsh pink glow)
const Color neonTextStart = Colors.white;
const Color neonTextEnd = cardGradientStart; // Shimmer effect to Soft Teal


class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
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

  // --- Firebase Logic (UNCHANGED) ---
  Future<void> _saveUserData() async {
    if (_incomeController.text.isEmpty || _goal == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill in income and select a goal.")),);
      }
      return;
    }

    try {
      // NOTE: Using 'local_user' document ID for demonstration persistence.
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

  // --- Navigation Logic (UNCHANGED) ---
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

  // --- Reusable Widget: Stylized Illustration Area (for Page 1, 3, 4) ---
  Widget _buildIllustrationArea(IconData icon, String title) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: cardBackground, // Medium Blue background circle
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: cardShadowColor, // Theme shadow color
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(
            icon,
            size: 80,
            color: cardIconColor, // Lighter accent blue icon color
          ),
        ),
        const SizedBox(height: 15),
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: accentPrimary, // White for title
          ),
        ),
      ],
    );
  }

  // --- Helper Widget for Styled TextField (Dark Card theme) ---
  Widget _buildDarkCardTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardBackground, // Medium Blue for the input
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: cardShadowColor, // Theme shadow color
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: cardTextPrimary, fontWeight: FontWeight.w600), // White text
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: cardTextSecondary.withOpacity(0.7), fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, color: cardIconColor), // Lighter accent blue icon

          enabledBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cardBorder, width: 2), // Lighter accent blue border
            borderRadius: BorderRadius.circular(15),
          ),
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: cardGradientStart, width: 3), // Soft Teal focus accent
            borderRadius: BorderRadius.circular(15),
          ),
          fillColor: Colors.transparent, 
          filled: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            // Dark Navy Blue Theme Background
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
                    child: Text(
                      _currentPage < 3 ? "Skip" : "Review",
                      style: const TextStyle(
                        color: accentSecondary, // Very Light Blue text
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ),

              // Page Content Area
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (index) {
                    setState(() => _currentPage = index);
                  },
                  children: [
                    _buildIntroPage(),
                    _buildNameOccupationPage(),
                    _buildIncomeGoalPage(),
                    _buildSettingsPage(),
                  ],
                ),
              ),

              // Page Indicator
              SmoothPageIndicator(
                controller: _controller,
                count: 4,
                effect: ExpandingDotsEffect(
                  activeDotColor: actionGradientStart, // Soft Teal active dot
                  dotColor: accentSecondary.withOpacity(0.5), 
                  dotHeight: 8,
                  dotWidth: 8,
                ),
              ),
              const SizedBox(height: 20),

              // Action Button (Teal to Indigo Gradient)
              Padding(
                padding: const EdgeInsets.only(bottom: 30, left: 30, right: 30),
                child: GestureDetector(
                  onTap: _nextPage,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        // ACTION BUTTON GRADIENT: Teal to Indigo
                        colors: [actionGradientStart, actionGradientEnd],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: cardGradientEnd.withOpacity(0.4), // Glow matching Indigo end color
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        )
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _currentPage == 3 ? "Save & Start FinTrackU" : "Get Started", 
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

  // ================= 1. Welcome/Intro Page =================
  Widget _buildIntroPage() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // INCREASED IMAGE SIZE (350x350)
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/opening.png',
              height: 350, 
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40),

          // SHINING NEON TEXT (THEME COLORS) - No Glow
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [neonTextStart, neonTextEnd], // White to Soft Teal
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: const Text( 
              "Welcome to FinTrackU",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34, 
                fontWeight: FontWeight.w900,
                color: Colors.white, // Essential for ShaderMask
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // BOLDER SUBTITLE (White for Contrast)
          const Text(
            "Manage your money smarter and achieve your financial goals effortlessly!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: accentPrimary, 
              height: 1.6, 
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  // ================= 2. Name & Occupation Page =================
  Widget _buildNameOccupationPage() {
    return Column(
      children: [
        Expanded(
          flex: 1,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(LucideIcons.userCheck, size: 80, color: accentPrimary), 
                const SizedBox(height: 10),
                const Text(
                  "Join FinTrackU",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: accentPrimary, 
                  ),
                ),
                const SizedBox(height: 5),
              ],
            ),
          ),
        ),

        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(30),
            margin: const EdgeInsets.only(top: 20),
            decoration: BoxDecoration(
              color: cardBackground, // Medium Blue card background
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(40),
                topRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Personal Info",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: cardTextPrimary, 
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    "This helps us personalize your budgeting experience.",
                    style: TextStyle(fontSize: 14, color: cardTextSecondary), 
                  ),
                  const Divider(height: 30, color: lightAccent),
                  
                  _buildDarkCardTextField(
                    controller: _nameController,
                    label: "Your Full Name",
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),

                  _buildDarkCardTextField(
                    controller: _ageController,
                    label: "Your Age",
                    icon: Icons.cake_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 20),

                  _buildDarkCardTextField(
                    controller: _occupationController,
                    label: "Current Course/Occupation",
                    icon: Icons.book_outlined,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= 3. Income & Goal Page =================
  Widget _buildIncomeGoalPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIllustrationArea(Icons.account_balance_wallet_outlined, "Income & Goals"),
          const SizedBox(height: 30),

          const Text(
            "Financial Goals & Income",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: accentPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            "This helps us calculate personalized budget recommendations.",
            style: TextStyle(fontSize: 14, color: accentSecondary),
          ),
          const SizedBox(height: 30),

          _buildDarkCardTextField( 
            controller: _incomeController,
            label: "Average Monthly Income (RM)",
            icon: Icons.attach_money,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 30),
          const Text("What is your main financial objective?",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: accentPrimary)), 
          const SizedBox(height: 15),

          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _buildGoalCardForDarkTheme("Save More"),
              _buildGoalCardForDarkTheme("Pay Off Debts"),
              _buildGoalCardForDarkTheme("Invest"),
              _buildGoalCardForDarkTheme("Budgeting"),
            ],
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }

  // --- Helper Widget for Goal Card (Dark theme) ---
  Widget _buildGoalCardForDarkTheme(String title) {
    final selected = _goal == title;
    return GestureDetector(
      onTap: () => setState(() => _goal = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? actionGradientStart : cardBackground, // Teal or Medium Blue
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: selected ? actionGradientEnd : cardBorder, // Indigo or Lighter accent blue border
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
              color: selected ? accentPrimary : accentSecondary, // White or Very Light Blue
              fontWeight: FontWeight.w700),
        ),
      ),
    );
  }


  // ================= 4. Settings Page =================
  Widget _buildSettingsPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildIllustrationArea(Icons.tune_rounded, "Personal Preferences"),
          const SizedBox(height: 30),

          const Text(
            "Customize Your App",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: accentPrimary),
          ),
          const SizedBox(height: 10),
          const Text(
            "These settings can be changed anytime in the main menu.",
            style: TextStyle(fontSize: 14, color: accentSecondary),
          ),
          const SizedBox(height: 30),

          // Notifications Switch
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
            decoration: BoxDecoration(
              border: Border.all(color: cardBorder, width: 1.5),
              borderRadius: BorderRadius.circular(15),
              color: cardBackground, // Medium Blue fill
              boxShadow: [
                BoxShadow(
                  color: cardShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: SwitchListTile(
              title: const Text("Enable spending reminders", style: TextStyle(color: cardTextPrimary, fontWeight: FontWeight.w700)),
              subtitle: const Text("Receive timely alerts to stay within budget.", style: TextStyle(color: cardTextSecondary)),
              value: _notifications,
              onChanged: (val) => setState(() => _notifications = val),
              activeColor: cardGradientStart, // Soft Teal accent
              inactiveThumbColor: Colors.grey.shade600,
              inactiveTrackColor: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 20),

          // Theme Dropdown
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: cardShadowColor,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: "App Theme",
                labelStyle: TextStyle(color: cardTextSecondary.withOpacity(0.7), fontWeight: FontWeight.w500),
                prefixIcon: Icon(Icons.palette_outlined, color: cardIconColor),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: cardBorder, width: 1.5),
                  borderRadius: BorderRadius.circular(15),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: cardGradientEnd, width: 3), // Soft Indigo focus
                  borderRadius: BorderRadius.circular(15),
                ),
                fillColor: cardBackground, // Medium Blue fill
                filled: true,
              ),
              value: _theme,
              style: const TextStyle(color: cardTextPrimary, fontWeight: FontWeight.w600), // White text
              dropdownColor: darkStart, // Dark dropdown menu background
              icon: const Icon(Icons.arrow_drop_down, color: accentPrimary),
              onChanged: (val) => setState(() => _theme = val!),
              items: [
                DropdownMenuItem(value: "light", child: Text("Light", style: TextStyle(color: accentPrimary))),
                DropdownMenuItem(value: "dark", child: Text("Dark", style: TextStyle(color: accentPrimary))),
                DropdownMenuItem(value: "auto", child: Text("Auto (System)", style: TextStyle(color: accentPrimary))),
              ],
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}