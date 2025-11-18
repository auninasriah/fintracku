import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math'; // For min/max in progress bar

// Import your pages (assuming these are defined elsewhere)
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
const Color spendingRed = Color(0xFFC62828);
const Color spendingGreen = Color(0xFF4CAF50);

// ================= PLACEHOLDER PAGES (For navigation) =================
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
      'imageUrl': 'https://images.unsplash.com/photo-1517048676732-d65bc937f952?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3wxMjA3fDB8MXxzZWFyY2h8MTl8fHNpZGUlMjBodXN0bGV8ZW58MHx8fHwxNjk5NDQ1Mjg0fDA&ixlib=rb-4.0.3&q=80&w=1080',
    },
    {
      'title': 'Pay Yourself First',
      'subtitle': 'Save a small amount immediately after receiving your allowance.',
      'color': const Color(0xFFC62828), // Red
      'imageUrl': 'https://images.unsplash.com/photo-1593341646782-adf922880b26?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3wxMjA3fDB8MXxzZWFyY2h8MTV8fHNhdmV8ZW58MHx8fHwxNjk5NDQ1NjUzfDA&ixlib=rb-4.0.3&q=80&w=1080',
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

// ================= HOME PAGE (UPDATED - CLEANER ACTIONS) =================
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // State variable to control balance visibility
  bool _isBalanceVisible = true;
  // Placeholder budget for the spending card logic
  final double _monthlyBudgetGoal = 1200.00; 

  // --- Firestore Stream for Income ---
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
        final amount = doc['amount'];
        if (amount is int) {
          total += amount.toDouble();
        } else if (amount is double) {
          total += amount;
        }
      }
      return total;
    });
  }

  // --- New Firestore Stream for Expenses ---
  Stream<double> _getTotalExpensesStream() {
    // Determine the start and end of the current month
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    final userId = 'local_user';
    return FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('expenses')
        // Filter by date for the current month (assuming a 'timestamp' field)
        .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
        .where('timestamp', isLessThanOrEqualTo: endOfMonth)
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        final amount = doc['amount'];
        if (amount is int) {
          total += amount.toDouble();
        } else if (amount is double) {
          total += amount;
        }
      }
      return total;
    });
  }


  // --- WIDGET 1: Gradient Income Card (Balance Card) ---
  Widget _incomeCard(BuildContext context) {
    // Note: This card still uses Total Income.
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
            gradient: LinearGradient(
              colors: [cardGradientStart, cardGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(35), 
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
                        fontSize: 32, 
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

  // --- WIDGET 2: Quick Actions (Reverted Icons and Simplified Colors) ---
  Widget _quickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      padding: const EdgeInsets.all(16), 
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22), 
        boxShadow: [
          BoxShadow(
              color: Colors.black.withAlpha(15),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text is now outside the icon row for better separation
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, left: 8.0, top: 4.0),
            child: Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.black, // Changed to black for simplicity
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Reverted to original icons and using primaryBlue for color
              _actionItem(context, LucideIcons.wallet, 'Income', const IncomePage(), primaryBlue), 
              _actionItem(context, LucideIcons.trendingDown, 'Expenses', const ExpensesPage(), primaryBlue), 
              _actionItem(context, LucideIcons.barChart2, 'Finance', const FinancePage(), primaryBlue), 
            ],
          ),
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: actionIconBackground,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withAlpha(10), blurRadius: 6, offset: const Offset(0, 4))
              ],
            ),
            // Icon color is now primaryBlue (passed as iconColor)
            child: Icon(icon, size: 28, color: iconColor), 
          ),
          const SizedBox(height: 8),
          // Text color is now primaryBlue
          Text(label, style: const TextStyle(fontSize: 12, color: primaryBlue, fontWeight: FontWeight.w600)), 
        ],
      ),
    );
  }

  // --- WIDGET 3 (NEW): Current Month's Spending Summary Card ---
  Widget _CurrentSpendingCard(BuildContext context) {
    return StreamBuilder<double>(
      stream: _getTotalExpensesStream(),
      builder: (context, snapshot) {
        final currentSpending = snapshot.data ?? 0.0;
        final budgetGoal = _monthlyBudgetGoal;
        
        // Calculate the progress percentage (clamped between 0.0 and 1.0)
        final progress = min(currentSpending / budgetGoal, 1.0);
        
        // Determine color based on progress (red if over 80%)
        final progressColor = progress > 0.8 ? spendingRed : cardGradientEnd;

        return GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesPage())),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This Month\'s Spending',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue),
                ),
                const SizedBox(height: 10),
                
                // Spending Amount
                Text(
                  'RM ${currentSpending.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: spendingRed,
                  ),
                ),
                const SizedBox(height: 15),

                // Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 10,
                  borderRadius: BorderRadius.circular(5),
                ),
                const SizedBox(height: 8),

                // Details and Goal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% of budget used',
                      style: TextStyle(fontSize: 12, color: progressColor, fontWeight: FontWeight.w600),
                    ),
                    Text(
                      'Goal: RM ${budgetGoal.toStringAsFixed(2)}',
                      style: const TextStyle(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
                
                const SizedBox(height: 10),
                // Call to action button
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View all Transactions ',
                      style: TextStyle(fontSize: 13, color: cardGradientEnd, fontWeight: FontWeight.bold),
                    ),
                    Icon(LucideIcons.arrowRight, size: 16, color: cardGradientEnd),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _incomeCard(context),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _quickActions(context),
                const SizedBox(height: 18),
                
                _CurrentSpendingCard(context), 

                const SizedBox(height: 24),
                
                // Additional Tips Section
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'Additional Tips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black, 
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                const AutoSlidingInfoCarousel(),
                const SizedBox(height: 40),
              ],
            ),
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