// ...existing code...
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:math'; // For min/max in progress bar

// Import your pages (assuming these are defined elsewhere)
import 'income_page.dart';
import 'expenses_page.dart';
import 'budget_page.dart';
import 'smart_spend_page.dart'; 

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

// ================= CHAT ASSISTANT WIDGET (NEW) =================

/// Represents a single message in the chat.
class ChatMessage {
  final String text;
  final String sender; // 'user' or 'assistant'
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.sender,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _messages = [
    ChatMessage(
      text: "Hello! I'm your Student Finance Assistant. I can help answer quick questions about budgeting and money management.",
      sender: 'assistant',
      timestamp: DateTime.now(),
    ),
  ];
  bool _isSending = false;

  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    // 1. Add user message
    setState(() {
      _messages.add(ChatMessage(text: text, sender: 'user', timestamp: DateTime.now()));
      _controller.clear();
      _isSending = true;
    });

    // Scroll to the bottom to show the new user message
    _scrollToBottom();

    // 2. Simulate AI API call (replace this with actual Gemini API call)
    final assistantResponse = await _getAssistantResponse(text);

    // 3. Add assistant response
    setState(() {
      _messages.add(ChatMessage(
        text: assistantResponse,
        sender: 'assistant',
        timestamp: DateTime.now().add(const Duration(seconds: 1)),
      ));
      _isSending = false;
    });

    // Scroll to the bottom to show the new assistant message
    _scrollToBottom();
  }

  Future<String> _getAssistantResponse(String prompt) async {
    // --- START: GEMINI API PLACEHOLDER ---
    // In a real Flutter app, you would make an HTTP request here.
    await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

    if (prompt.toLowerCase().contains('budget') || prompt.toLowerCase().contains('spending')) {
      return "Budgeting tip: Try the '50/30/20 Rule'—50% needs, 30% wants, 20% savings. Our Budget tab can help you track this!";
    } else if (prompt.toLowerCase().contains('expense')) {
      return "To track a new expense, simply tap the 'Expenses' button in the Quick Actions section on the Home Page.";
    } else if (prompt.toLowerCase().contains('hello') || prompt.toLowerCase().contains('hi')) {
      return "Hi there! How can I assist you with your finances today? Try asking for a budgeting tip!";
    } else {
      return "I'm focusing on student finance advice. Can you ask me about budgeting, saving, or tracking expenses?";
    }
    // --- END: GEMINI API PLACEHOLDER ---
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Finance Assistant'),
        backgroundColor: cardGradientStart,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Message List
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.sender == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8.0),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                    ),
                    decoration: BoxDecoration(
                      color: isUser ? primaryBlue : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(2),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, -2))
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    enabled: !_isSending,
                    decoration: InputDecoration(
                      hintText: _isSending ? 'Assistant is typing...' : 'Ask a finance question...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25.0),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    ),
                    onSubmitted: _isSending ? null : (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8.0),
                GestureDetector(
                  onTap: _isSending ? null : _sendMessage,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isSending ? Colors.grey : primaryBlue,
                    ),
                    child: _isSending
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              strokeWidth: 3,
                            ),
                          )
                        : const Icon(LucideIcons.send, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
            color: _currentPage == index ? primaryBlue : const Color(0x64BDBDBD), // grey with alpha ~100
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
  Widget _currentSpendingCard(BuildContext context) {
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
                  // borderRadius is supported in newer Flutter; if your SDK doesn't support it, remove this line.
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
    return Stack(
      children: [
        Column(
          children: [
            _incomeCard(context),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _quickActions(context),
                    const SizedBox(height: 18),
                    
                    _currentSpendingCard(context), 

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
        ),

        // --- 2. Floating Chat Button (Positioned at the bottom right) ---
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () {
              // Navigate to the full-screen ChatScreen
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ChatScreen()),
              );
            },
            heroTag: "chatFab",
            backgroundColor: primaryBlue,
            shape: const CircleBorder(),
            child: const Icon(
              LucideIcons.messageSquare, 
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}


// ================= BEAUTIFUL CUSTOM BOTTOM NAV =================
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
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
      decoration: BoxDecoration(
        color: const Color(0xEBFFFFFF), // Colors.white.withOpacity(0.92)
        borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000), // Colors.black.withOpacity(0.08)
            blurRadius: 20,
            offset: const Offset(0, -4),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(LucideIcons.home, "Home", 0),
          _navItem(LucideIcons.sparkles, "Smart", 1),
          _navItem(LucideIcons.pieChart, "Savings", 2),
          _navItem(LucideIcons.settings, "Settings", 3),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final bool active = index == currentIndex;

    return GestureDetector(
      onTap: () => onTap(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
        decoration: BoxDecoration(
          color: active ? primaryBlue : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: const Color(0x5911355F), // primaryBlue.withOpacity(0.35)
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  )
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: active ? 24 : 22,
              color: active ? Colors.white : primaryBlue,
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : Colors.black54,
              ),
              child: Text(label),
            )
          ],
        ),
      ),
    );
  }
}
// ...existing code...