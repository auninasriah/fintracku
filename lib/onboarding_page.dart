import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ❌ DIBUANG: Import 'home_page.dart' tidak diperlukan lagi
import 'main.dart'; // theme colors (Untuk primaryBlue)

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  // Input controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _incomeController = TextEditingController();

  String? _goal;
  bool _notifications = true;
  String _theme = "light";

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _incomeController.dispose();
    super.dispose();
  }

  // Save data to Firestore
  Future<void> _saveUserData() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc('local_user').set({
        'name': _nameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'monthly_income': double.tryParse(_incomeController.text) ?? 0,
        'goal': _goal,
        'notifications_enabled': _notifications,
        'theme': _theme,
        'created_at': DateTime.now(),
      });

      if (!mounted) return;

      // ✅ NAVIGASI: Menggunakan Named Route
      Navigator.pushReplacementNamed(context, '/home'); 

    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    }
  }

  // Navigate to next page or save data
  void _nextPage() {
    if (_currentPage < 3) {
      _controller.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.easeInOutCubic);
    } else {
      _saveUserData();
    }
  }

  // Skip onboarding directly
  void _skip() {
    // ✅ NAVIGASI: Menggunakan Named Route
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Top bar with Skip button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _skip,
                      child: const Text(
                        "Skip",
                        style: TextStyle(
                          color: primaryBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView(
                    controller: _controller,
                    onPageChanged: (index) {
                      setState(() => _currentPage = index);
                    },
                    children: [
                      _buildIntroPage(),
                      _buildNameAgePage(),
                      _buildIncomeGoalPage(),
                      _buildSettingsPage(),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SmoothPageIndicator(
                  controller: _controller,
                  count: 4,
                  effect: WormEffect(
                    activeDotColor: primaryBlue,
                    dotColor: Colors.grey.shade300,
                    dotHeight: 10,
                    dotWidth: 10,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: GestureDetector(
                    onTap: _nextPage,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF234E70), Color(0xFF11355F)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(38), 
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Text(
                        _currentPage == 3 ? "Save & Start" : "Next",
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ... (Kod _buildIntroPage, _buildNameAgePage, _buildIncomeGoalPage, _goalCard, dan _buildSettingsPage tidak berubah)
// [Kod-kod widget lain dihilangkan untuk ringkasan, sila gunakan kod anda yang asal]
  
  // ================= PAGE 1 =================
  Widget _buildIntroPage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.account_balance_wallet, size: 100, color: primaryBlue),
        const SizedBox(height: 30),
        const Text(
          "Welcome to FinTrackU",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: primaryBlue),
        ),
        const SizedBox(height: 10),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 40),
          child: Text(
            "Manage your money smarter and achieve your financial goals effortlessly!",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  // ================= PAGE 2 =================
  Widget _buildNameAgePage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Let’s get to know you ✨",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue)),
          const SizedBox(height: 20),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: "Your Name", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Your Age", border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }

  // ================= PAGE 3 =================
  Widget _buildIncomeGoalPage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Financial Details 💰",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue)),
          const SizedBox(height: 20),
          TextField(
            controller: _incomeController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Monthly Income (RM)", border: OutlineInputBorder()),
          ),
          const SizedBox(height: 20),
          const Text("What is your main financial goal?",
              style: TextStyle(fontSize: 16, color: Colors.black87)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [
              _goalCard("Save More"),
              _goalCard("Pay Off Debts"),
              _goalCard("Save for a Big Goal"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _goalCard(String title) {
    final selected = _goal == title;
    return GestureDetector(
      onTap: () => setState(() => _goal = title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(colors: [Color(0xFF3B5998), Color(0xFF234E70)])
              : const LinearGradient(colors: [Color(0xFFE6F0FF), Color(0xFFE8F6FF)]),
          borderRadius: BorderRadius.circular(12),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: Colors.black.withAlpha(38),
                      blurRadius: 6,
                      offset: const Offset(0, 3))
                ]
              : [],
        ),
        child: Text(
          title,
          style: TextStyle(color: selected ? Colors.white : primaryBlue, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ================= PAGE 4 =================
  Widget _buildSettingsPage() {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Final Settings ⚙️",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: primaryBlue)),
          const SizedBox(height: 20),
          SwitchListTile(
            title: const Text("Enable spending reminders"),
            value: _notifications,
            onChanged: (val) => setState(() => _notifications = val),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "App Theme", border: OutlineInputBorder()),
            value: _theme,
            onChanged: (val) => setState(() => _theme = val!),
            items: const [
              DropdownMenuItem(value: "light", child: Text("Light")),
              DropdownMenuItem(value: "dark", child: Text("Dark")),
              DropdownMenuItem(value: "auto", child: Text("Auto")),
            ],
          ),
          const SizedBox(height: 30),
          const Center(
            child: Text(
              "Your data will be securely stored in Firestore.",
              style: TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}