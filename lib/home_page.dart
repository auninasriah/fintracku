import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
// Import your pages
import 'income_page.dart';
import 'expenses_page.dart';
import 'budget_page.dart';

// --- COLOR DEFINITIONS ---
const Color primaryBlue = Color(0xFF11355F); // Dark Navy Blue
const Color accentBlue = Color(0xFF234A78); // Medium Blue
const Color lightAccent = Color(0xFF4A72AE); // Lighter accent blue

// --- NEW DESIGN COLORS ---
const Color cardGradientStart = Color(0xFF3B8D99); // Soft Teal for balance card gradient
const Color cardGradientEnd = Color(0xFF4F67B5); // Soft Indigo for balance card gradient
const Color actionIconBackground = Color(0xFFE8F5FF); // Very Light Blue for quick actions background
const Color cardShadowColor = Color(0x3311355F); // Shadow for primary elements

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

// ================= MAIN SHELL (UNCHANGED) =================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    SafeArea(child: HomePage()), // HomePage is now Stateful
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

// ================= AUTO SLIDING CAROUSEL (UNCHANGED) =================
class AutoSlidingInfoCarousel extends StatefulWidget {
  const AutoSlidingInfoCarousel({super.key});

  @override
  State<AutoSlidingInfoCarousel> createState() => _AutoSlidingInfoCarouselState();
}

class _AutoSlidingInfoCarouselState extends State<AutoSlidingInfoCarousel> {
  final PageController _pageController = PageController(initialPage: 0);
  late Timer _timer;
  int _currentPage = 0;

  final List<Map<String, dynamic>> carouselItems = [
    {
      'title': 'Student Budgeting 101',
      'subtitle': 'Spend less than you earn! Track your money diligently.',
      'color': const Color(0xFF00ADB5), // Teal
      'imageUrl': 'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    },
    {
      'title': 'The Power of Habit',
      'subtitle': 'Your tiny daily spending habits define your financial future.',
      'color': const Color(0xFF2E8BC0), // Bright Blue
      'imageUrl': 'https://images.unsplash.com/photo-1579621970795-87facc2f976d?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    },
    {
      'title': 'Need a Side Hustle?',
      'subtitle': 'Explore simple ways to earn extra cash between classes.',
      'color': const Color(0xFF6A1B9A), // Deep Purple
      'imageUrl': 'https://images.unsplash.com/photo-1542838132-92c90c611488?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    },
    {
      'title': 'Pay Yourself First',
      'subtitle': 'Save a small amount immediately after receiving your allowance.',
      'color': const Color(0xFFC62828), // Red
      'imageUrl': 'https://images.unsplash.com/photo-1563986968856-43b85994f83b?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(const Duration(seconds: 5), (Timer timer) {
      if (_pageController.hasClients) {
        int nextPage = (_currentPage + 1) % carouselItems.length;

        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Widget _carouselCard({
    required String title,
    required String subtitle,
    required Color color,
    required String imageUrl,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: color.withAlpha(50),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Stack(
        children: [
          // Background Image (Faded from network)
          Positioned(
            right: -20,
            bottom: 0,
            top: 0,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                width: 150,
                opacity: const AlwaysStoppedAnimation(0.3),
                errorBuilder: (context, error, stackTrace) => const Center(
                    child: Icon(LucideIcons.image,
                        color: Colors.white54, size: 80)),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDotIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: carouselItems.map((item) {
        int index = carouselItems.indexOf(item);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          height: 6.0,
          width: _currentPage == index ? 16.0 : 6.0,
          decoration: BoxDecoration(
            color: _currentPage == index ? primaryBlue : Colors.grey.withAlpha(100),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 150,
          child: PageView.builder(
            controller: _pageController,
            itemCount: carouselItems.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              final item = carouselItems[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                child: _carouselCard(
                  title: item['title'],
                  subtitle: item['subtitle'],
                  color: item['color'],
                  imageUrl: item['imageUrl'],
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        _buildDotIndicator(),
      ],
    );
  }
}

// ================= HOME PAGE (MODIFIED) =================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // New state variable to control balance visibility
  bool _isBalanceVisible = true;

  Stream<double> _getTotalIncomeStream() {
    final userId = 'local_user';
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('income')
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        // Ensure 'amount' is treated as a double
        final amount = doc['amount'];
        if (amount is int) {
          total += amount.toDouble();
        } else if (amount is double) {
          total += amount;
        }
        // Handle potential null or non-numeric data gracefully
      }
      return total;
    });
  }

  // --- WIDGET 1: Gradient Income Card (Balance Card) ---
  Widget _incomeCard(BuildContext context) {
    return StreamBuilder<double>(
      stream: _getTotalIncomeStream(),
      builder: (context, snapshot) {
        final balance = snapshot.data ?? 0.0;
        final displayBalance = _isBalanceVisible
            ? balance.toStringAsFixed(2)
            : '******'; // Hide balance logic
        final displayIcon = _isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff;

        return Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            top: MediaQuery.of(context).padding.top + 24,
            bottom: 28,
          ),
          decoration: const BoxDecoration(
            // Use a softer gradient for the balance card
            gradient: LinearGradient(
              colors: [cardGradientStart, cardGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(35), // Slightly larger curve
              bottomRight: Radius.circular(35),
            ),
            boxShadow: [
              BoxShadow(
                  color: cardShadowColor, blurRadius: 10, offset: Offset(0, 5))
            ],
          ),
          child: Column(
            children: [
              // Title
              const Text(
                'Total Income',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 14),

              // Balance Display
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isBalanceVisible ? 'RM ' : '', // Only show RM when visible
                    style: const TextStyle(color: Colors.white70, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    displayBalance,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32, // Larger font size for impact
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2),
                  ),

                  // Toggle Button
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isBalanceVisible = !_isBalanceVisible;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(displayIcon, color: Colors.white70, size: 22),
                    ),
                  ),
                ],
              ),

              // Loading indicator
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

  // --- WIDGET 2: Quick Actions (Redesigned) ---
  Widget _quickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      padding: const EdgeInsets.all(16), // Increased padding
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22), // More rounded corners
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionItem(context, LucideIcons.wallet, 'Income', const IncomePage(), primaryBlue),
          _actionItem(context, LucideIcons.trendingDown, 'Expenses', const ExpensesPage(), const Color(0xFFC62828)), // Red for expenses
          _actionItem(context, LucideIcons.barChart2, 'Finance', const FinancePage(), const Color(0xFF0D47A1)), // Deeper Blue for finance
        ],
      ),
    );
  }

  Widget _actionItem(BuildContext context, IconData icon, String label, Widget page, Color iconColor) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14), // Increased padding
            decoration: BoxDecoration(
              // Simple, soft background
              color: actionIconBackground,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 4))
              ],
            ),
            child: Icon(icon, size: 28, color: iconColor), // Dynamic color
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 12, color: primaryBlue, fontWeight: FontWeight.w600)), // Darker text
        ],
      ),
    );
  }

  // --- WIDGET 3: Info Cards (Redesigned) ---
  Widget _infoCards() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20), // Increased padding
      decoration: BoxDecoration(
        color: primaryBlue, // Retain dark blue background
        borderRadius: BorderRadius.circular(22), // Matching corner radius
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quick Tips', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
          const Divider(color: Colors.white30, height: 25),
          _infoRow(LucideIcons.creditCard, 'TRACK YOUR SPENDING',
              'Add your expenses to see how you spend your money'),
          const SizedBox(height: 15), // Increased spacing
          _infoRow(LucideIcons.bookOpen, 'BUILD A BUDGET',
              'Know how much you can spend by making a budget for it'),
          const SizedBox(height: 15),
          _infoRow(LucideIcons.users, 'KEEP TRACK TOGETHER',
              'Share budget and transactions to see who paid for what'),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String title, String subtitle) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start, // Align to top
      children: [
        Container(
          padding: const EdgeInsets.all(8), // Smaller padding for icon container
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: cardGradientEnd, size: 20), // Use accent color
        ),
        const SizedBox(width: 15), // Increased spacing
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)), // Bolder title
              const SizedBox(height: 2),
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
        const SizedBox(height: 18),
        const AutoSlidingInfoCarousel(),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 24),
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

// ================= CUSTOM BOTTOM NAV (Slightly Refined) =================
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
                      BoxShadow(color: accentBlue.withAlpha(51), blurRadius: 8, offset: const Offset(0, 4))
                    ]
                  : null,
            ),
            child: Icon(icon, size: 22, color: active ? Colors.white : primaryBlue),
          ),
          const SizedBox(height: 6),
          // Bolder text on hover
          Text(label, style: TextStyle(fontSize: 11, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? primaryBlue : Colors.black54)),
        ],
      ),
    );
  }
}