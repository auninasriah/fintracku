import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'main.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'income_page.dart';
import 'expenses_page.dart';

// ================= MAIN SHELL =================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    SafeArea(child: HomePage()), // ✅ Added SafeArea here
    SmartSpendPage(),
    BudgetPage(),
    SettingsPage(),
  ];

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}

// ================= HOME PAGE =================
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Stream<double> _getTotalIncomeStream() {
    final userId = 'local_user'; // ✅ Same as onboarding Firestore doc ID
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('income')
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += (doc['amount'] ?? 0).toDouble();
      }
      return total;
    });
  }

  Widget _incomeCard(BuildContext context) {
    return StreamBuilder<double>(
      stream: _getTotalIncomeStream(),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 24,
            bottom: 28,
          ),
          decoration: const BoxDecoration(
            color: primaryBlue,
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
          ),
          child: Column(
            children: [
              const Text(
                'Total Income',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('RM ',
                      style: TextStyle(color: Colors.white70, fontSize: 18)),
                  Text(
                    balance.toStringAsFixed(2),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.eye, color: Colors.white70, size: 18),
                ],
              ),
              if (snapshot.connectionState == ConnectionState.waiting)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: CircularProgressIndicator(
                      color: Colors.white70, strokeWidth: 2),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _quickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionItem(context, LucideIcons.wallet, 'Income', const IncomePage()),
          _actionItem(context, LucideIcons.trendingUp, 'Expenses', const ExpensesPage()),
          _actionItem(context, LucideIcons.barChart2, 'Finance', const FinancePage()),
        ],
      ),
    );
  }

  Widget _actionItem(BuildContext context, IconData icon, String label, Widget page) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFFDBF0FF), Color(0xFFE8F5FF)]),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withAlpha(15), blurRadius: 6, offset: const Offset(0, 4))
              ],
            ),
            child: Icon(icon, size: 26, color: primaryBlue),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _infoCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoRow(LucideIcons.creditCard, 'TRACK YOUR SPENDING',
              'Add your expenses to see how you spend your money'),
          const SizedBox(height: 12),
          _infoRow(LucideIcons.bookOpen, 'BUILD A BUDGET',
              'Know how much you can spend by making a budget for it'),
          const SizedBox(height: 12),
          _infoRow(LucideIcons.users, 'KEEP TRACK TOGETHER',
              'Share budget and transactions to see who paid for what'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: primaryBlue, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        )
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _incomeCard(context),
        _quickActions(context),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: [
              _infoCards(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ],
    );
  }
}

// ================= DUMMY PAGES =================

class FinancePage extends StatelessWidget {
  const FinancePage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Finance')),
      body: const Center(child: Text('This is the Finance page.')),
    );
  }
}

class SmartSpendPage extends StatelessWidget {
  const SmartSpendPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Spend')),
      body: const Center(child: Text('Smart Spend features go here')),
    );
  }
}

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Budget')),
      body: const Center(child: Text('Budget features go here')),
    );
  }
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(child: Text('Settings page')),
    );
  }
}

// ================= CUSTOM BOTTOM NAV =================
class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          // ✅ DIBAIKI: Tukar withValues kepada withAlpha(12)
          BoxShadow(color: Colors.black.withAlpha(12), blurRadius: 12)
        ],
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(18), topRight: Radius.circular(18)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(LucideIcons.home, 'Home', 0),
          _navItem(LucideIcons.sparkles, 'Smart Spend', 1),
          _navItem(LucideIcons.pieChart, 'Budget', 2),
          _navItem(LucideIcons.settings, 'Settings', 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool active = index == currentIndex;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: active ? accentBlue : Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: active
                  ? [
                      // ✅ DIBAIKI: Tukar withValues kepada withAlpha(51)
                      BoxShadow(color: accentBlue.withAlpha(51), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                  : null,
            ),
            child: Icon(icon, size: 22, color: active ? Colors.white : primaryBlue),
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 11, color: active ? primaryBlue : Colors.black54)),
        ],
      ),
    );
  }
}



