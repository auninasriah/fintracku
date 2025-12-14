// home_page.dart
import 'package:fintrack/ai_finance_assistant_page.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'dart:math'; 
import 'package:rxdart/rxdart.dart';
import 'income_page.dart';
import 'expenses_page.dart';
import 'savings_page.dart';
import 'smart_spend_page.dart';
import 'smart_spend_main_page.dart';
import 'finance_page.dart';
import 'settings_page.dart';
import 'profile_avatar.dart';
import 'profile_setup_page.dart';
import 'ai_finance_assistant_page.dart'; 

// --- COLOR DEFINITIONS (Vibrant Blue & Purple Theme) ---
const Color primaryBlue = Color(0xFF3C79C1); // Vibrant Light Blue
const Color accentBlue = Color(0xFF2A466F); // Deep Blue
const Color lightAccent = Color(0xFF3F2A61); // Vibrant Purple

// --- NEW DESIGN COLORS ---
const Color cardGradientStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple
const Color actionIconBackground = Color(0xFFE3EFFF); // Very Light Blue
const Color cardShadowColor = Color(0x333C79C1); // Shadow with vibrant blue tone
const Color spendingRed = Color(0xFFC62828);
const Color spendingGreen = Color(0xFF4CAF50);


// ================= CHAT ASSISTANT WIDGET =================

/// Represents a single message in the chat.
// class ChatMessage {
//   final String text;
//   final String sender; // 'user' or 'assistant'
//   final DateTime timestamp;

//   ChatMessage({
//     required this.text,
//     required this.sender,
//     required this.timestamp,
//   });
// }

// class ChatScreen extends StatefulWidget {
//   const ChatScreen({super.key});

//   @override
//   State<ChatScreen> createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final ScrollController _scrollController = ScrollController();
//   final List<ChatMessage> _messages = [
//     ChatMessage(
//       text:
//           "Hello! I'm your Student Finance Assistant. I can help answer quick questions about budgeting and money management.",
//       sender: 'assistant',
//       timestamp: DateTime.now(),
//     ),
//   ];
//   bool _isSending = false;

//   void _sendMessage() async {
//     final text = _controller.text.trim();
//     if (text.isEmpty) return;

//     setState(() {
//       _messages.add(ChatMessage(text: text, sender: 'user', timestamp: DateTime.now()));
//       _controller.clear();
//       _isSending = true;
//     });

//     _scrollToBottom();

//     final assistantResponse = await _getAssistantResponse(text);

//     if (!mounted) return; // ✅ FIXED: Guard with mounted check

//     setState(() {
//       _messages.add(ChatMessage(
//         text: assistantResponse,
//         sender: 'assistant',
//         timestamp: DateTime.now().add(const Duration(seconds: 1)),
//       ));
//       _isSending = false;
//     });

//     _scrollToBottom();
//   }

//   Future<String> _getAssistantResponse(String prompt) async {
//     await Future.delayed(const Duration(seconds: 1)); // Simulate network delay

//     final p = prompt.toLowerCase();
//     if (p.contains('budget') || p.contains('spending')) {
//       return "Budgeting tip: Try the '50/30/20 Rule'—50% needs, 30% wants, 20% savings. Our Budget tab can help you track this!";
//     } else if (p.contains('expense')) {
//       return "To track a new expense, simply tap the 'Expenses' button in the Quick Actions section on the Home Page.";
//     } else if (p.contains('hello') || p.contains('hi')) {
//       return "Hi there! How can I assist you with your finances today? Try asking for a budgeting tip!";
//     } else {
//       return "I'm focusing on student finance advice. Can you ask me about budgeting, saving, or tracking expenses?";
//     }
//   }

//   void _scrollToBottom() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (_scrollController.hasClients) {
//         _scrollController.animateTo(
//           _scrollController.position.maxScrollExtent,
//           duration: const Duration(milliseconds: 300),
//           curve: Curves.easeOut,
//         );
//       }
//     });
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     _scrollController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         flexibleSpace: Container(
//           decoration: const BoxDecoration(
//             gradient: LinearGradient(
//               colors: [cardGradientStart, cardGradientEnd],
//               begin: Alignment.topLeft,
//               end: Alignment.bottomRight,
//             ),
//           ),
//         ),
//         title: Text('AI Finance Assistant', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white)),
//         backgroundColor: Colors.transparent,
//         foregroundColor: Colors.white,
//         elevation: 0,
//       ),
//       body: Column(
//         children: [
//           // Message List
//           Expanded(
//             child: ListView.builder(
//               controller: _scrollController,
//               padding: const EdgeInsets.all(16.0),
//               itemCount: _messages.length,
//               itemBuilder: (context, index) {
//                 final message = _messages[index];
//                 final isUser = message.sender == 'user';
//                 return Align(
//                   alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
//                   child: Container(
//                     margin: const EdgeInsets.only(bottom: 8.0),
//                     padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
//                     constraints: BoxConstraints(
//                       maxWidth: MediaQuery.of(context).size.width * 0.75,
//                     ),
//                     decoration: BoxDecoration(
//                       color: isUser ? primaryBlue : Colors.grey.shade200,
//                       borderRadius: BorderRadius.circular(16).copyWith(
//                         bottomRight: isUser ? const Radius.circular(2) : const Radius.circular(16),
//                         bottomLeft: isUser ? const Radius.circular(16) : const Radius.circular(2),
//                       ),
//                     ),
//                     child: Text(
//                       message.text,
//                       style: GoogleFonts.inter(
//                         color: isUser ? Colors.white : Colors.black87,
//                         fontSize: 13.5,
//                         fontWeight: FontWeight.w400,
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),

//           // Input Field
//           Container(
//             padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               boxShadow: [
//                 BoxShadow(color: Colors.grey.shade300, blurRadius: 4, offset: const Offset(0, -2))
//               ],
//             ),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     enabled: !_isSending,
//                     style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
//                     decoration: InputDecoration(
//                       hintText: _isSending ? 'Assistant is typing...' : 'Ask a finance question...',
//                       hintStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400),
//                       border: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(25.0),
//                         borderSide: BorderSide.none,
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey.shade100,
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//                     ),
//                     onSubmitted: _isSending ? null : (_) => _sendMessage(),
//                   ),
//                 ),
//                 const SizedBox(width: 8.0),
//                 GestureDetector(
//                   onTap: _isSending ? null : _sendMessage,
//                   child: Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       shape: BoxShape.circle,
//                       color: _isSending ? Colors.grey : primaryBlue,
//                     ),
//                     child: _isSending
//                         ? const SizedBox(
//                             width: 24,
//                             height: 24,
//                             child: CircularProgressIndicator(
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                               strokeWidth: 3,
//                             ),
//                           )
//                         : const Icon(LucideIcons.send, color: Colors.white, size: 24),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }

// ================= ANIMATED PATTERN BACKGROUND =================
class AnimatedPatternBackground extends StatefulWidget {
  const AnimatedPatternBackground({super.key});

  @override
  State<AnimatedPatternBackground> createState() => _AnimatedPatternBackgroundState();
}

class _AnimatedPatternBackgroundState extends State<AnimatedPatternBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          painter: PatternPainter(_controller.value),
          child: Container(),
        );
      },
    );
  }
}

class PatternPainter extends CustomPainter {
  final double animationValue;

  PatternPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.08) // ✅ FIXED: Replaced withOpacity
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final spacing = 40.0;
    final offset = animationValue * spacing * 2;

    // Draw animated diagonal lines
    for (double i = -spacing; i < size.width + size.height; i += spacing) {
      final startX = i - offset;
      final startY = 0.0;
      final endX = i - offset + size.height;
      final endY = size.height;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
    }

    // Draw animated circles
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05) // ✅ FIXED: Replaced withOpacity
      ..style = PaintingStyle.fill;

    for (int i = 0; i < 5; i++) {
      final circleOffset = (animationValue + i * 0.2) % 1.0;
      final x = size.width * circleOffset;
      final y = size.height * 0.3 + sin(circleOffset * pi * 2) * 30;
      canvas.drawCircle(Offset(x, y), 20, circlePaint);
    }
  }

  @override
  bool shouldRepaint(PatternPainter oldDelegate) => true;
}


// ================= MAIN SHELL (UNCHANGED) =================
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;
  bool _hasCheckedOnboarding = false;
  bool _hasSeenSmartSpendOnboarding = false; // ✅ Track onboarding status

  // ✅ NEW: Dynamically build pages based on onboarding status
  List<Widget> _buildPages() {
    return [
      const SafeArea(child: HomePage()),
      _hasSeenSmartSpendOnboarding ? const SmartSpendMainPage() : const SmartSpendPage(),
      const SavingsPage(),
      const SettingsPage(),
    ];
  }

  @override
  void initState() {
    super.initState();
    _checkAndShowSmartSpendOnboarding();
  }

  /// Check if user has seen Smart Spend onboarding
  Future<void> _checkAndShowSmartSpendOnboarding() async {
    if (_hasCheckedOnboarding) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final hasSeenOnboarding = userDoc.data()?['hasSeenSmartSpendOnboarding'] ?? false;

      if (mounted) {
        setState(() {
          _hasSeenSmartSpendOnboarding = hasSeenOnboarding;
        });
      }

      _hasCheckedOnboarding = true;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
    }
  }

  void _onNavTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages(); // ✅ Build pages dynamically
    
    return Scaffold(
      body: pages[_selectedIndex],
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _selectedIndex,
        onTap: _onNavTapped,
      ),
    );
  }
}


// ================= AUTO SLIDING CAROUSEL =================
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
      'color': const Color(0xFF3C79C1), // Vibrant Light Blue
      'imageUrl':
          'https://images.unsplash.com/photo-1522071820081-009f0129c71c?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    },
    {
      'title': 'The Power of Habit',
      'subtitle': 'Your tiny daily spending habits define your financial future.',
      'color': const Color(0xFF2A466F), // Deep Blue
      'imageUrl':
          'https://images.unsplash.com/photo-1579621970795-87facc2f976d?q=80&w=2940&auto=format&fit=crop&ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D',
    },
    {
      'title': 'Need a Side Hustle?',
      'subtitle': 'Explore simple ways to earn extra cash between classes.',
      'color': const Color(0xFF3F2A61), // Vibrant Purple
      'imageUrl':
          'https://images.unsplash.com/photo-1517048676732-d65bc937f952?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3wxMjA3fDB8MXxzZWFyY2h8MTl8fHNpZGUlMjBodXN0bGV8ZW58MHx8fHwxNjk5NDQ1Mjg0fDA&ixlib=rb-4.0.3&q=80&w=1080',
    },
    {
      'title': 'Pay Yourself First',
      'subtitle': 'Save a small amount immediately after receiving your allowance.',
      'color': const Color(0xFFC62828), // Red
      'imageUrl':
          'https://images.unsplash.com/photo-1593341646782-adf922880b26?crop=entropy&cs=tinysrgb&fit=max&fm=jpg&ixid=M3wxMjA3fDB8MXxzZWFyY2h8MTV8fHNhdmV8ZW58MHx8fHwxNjk5NDQ1NjUzfDA&ixlib=rb-4.0.3&q=80&w=1080',
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
          BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 5)) // ✅ FIXED
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
                errorBuilder: (context, error, stackTrace) =>
                    const Center(child: Icon(LucideIcons.image, color: Colors.white54, size: 80)),
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
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
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
            color: _currentPage == index ? primaryBlue : const Color(0x64BDBDBD),
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

// ================= HOME PAGE (UI preserved, AUTH FIXED) =================
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

  // Get current user once
  User? get _user => FirebaseAuth.instance.currentUser;

  // --- Firestore Stream for User Name ---
  Stream<String> _getUserNameStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value('User');

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data() as Map<String, dynamic>;
        return data['name']?.toString() ?? 'User';
      }
      return 'User';
    });
  }

  // --- Firestore Stream for Income (auth + guards) ---
  Stream<double> _getTotalIncomeStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('income')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        final raw = data?['amount'];
        final parsed = raw is num
            ? raw.toDouble()
            : double.tryParse(raw?.toString() ?? '') ?? 0;

        total += parsed;
      }
      return total;
    });
  }

  // --- Firestore Stream for Expenses (auth + guards) ---
  Stream<double> _getTotalExpensesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThanOrEqualTo: end)
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;

        final raw = data?['amount'];
        final parsed = raw is num
            ? raw.toDouble()
            : double.tryParse(raw?.toString() ?? '') ?? 0;

        total += parsed;
      }
      return total;
    });
  }

    // --- Firestore Stream for Total Savings ---
  Stream<double> _getTotalSavingsStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savingsGoals')
        .snapshots()
        .map((snapshot) {
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        final amt = data?['currentAmount'];
        if (amt is int) total += amt.toDouble();
        if (amt is double) total += amt;
      }
      return total;
    });
  }

  // --- Firestore Stream for Current Balance (Income - Expenses + Savings) ---
  Stream<double> _getCurrentBalanceStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return Rx.combineLatest3(
      _getTotalIncomeStream(),
      _getTotalExpensesStream(),
      _getTotalSavingsStream(),
      (double income, double expenses, double savings) {
        return income - expenses + savings;
      },
    );
  } 

    // --- WIDGET 1: Gradient Income Card (Balance Card) with Name & Animated Pattern ---
  Widget _incomeCard(BuildContext context) {
    return StreamBuilder<String>(
      stream: _getUserNameStream(),
      builder: (context, nameSnapshot) {
        final userName = nameSnapshot.data ?? 'User';

        return StreamBuilder<double>(
          stream: _getCurrentBalanceStream(),
          builder: (context, balanceSnapshot) {
            final balance = balanceSnapshot.data ?? 0.0;
            final displayBalance = _isBalanceVisible ? balance.toStringAsFixed(2) : '••••••';
            final displayIcon = _isBalanceVisible ? LucideIcons.eye : LucideIcons.eyeOff;

            return Container(
              width: double.infinity,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top + 16,
                bottom: 24,
                left: 20,
                right: 20,
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
                  BoxShadow(color: cardShadowColor, blurRadius: 10, offset: Offset(0, 5))
                ],
              ),
              child: Stack(
                children: [
                  // Animated Pattern Background
                  const Positioned.fill(
                    child: AnimatedPatternBackground(),
                  ),

                  // Content
                  Column(
                    children: [
                      // Header: Profile Avatar + Welcome Message + Logout (side by side)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // Profile Avatar (tap to navigate to ProfileSetupPage)
                          ProfileAvatar(
                            radius: 18,
                            showEditIcon: true,
                            onTap: () async {  // ← Add 'async'
                              // Push the page and wait for result
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
                              );
                              
                              if (result == true && mounted) {
                                setState(() {
                                });
                              }
                            },
                          ),

                          const SizedBox(width: 12),

                          // Welcome Message with Glow
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.3), 
                                    blurRadius: 20,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 0),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Hye! Welcome,\n$userName',
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                  height: 1.2,
                                ),
                              ),
                            ),
                          ),

                          // Logout Button
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(LucideIcons.logOut, color: Colors.white, size: 20),
                              tooltip: 'Logout',
                              onPressed: () async {
                                if (!mounted) return; // ✅ Guard before showing dialog
                                
                                final confirmed = await showGeneralDialog<bool>(
                                  context: context,
                                  barrierDismissible: true,
                                  barrierLabel: '',
                                  transitionDuration: const Duration(milliseconds: 280),
                                  pageBuilder: (_, __, ___) => const SizedBox.shrink(),
                                  transitionBuilder: (context, animation, secondary, child) {
                                    final curved = CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOutBack,
                                    );

                                    return Transform.scale(
                                      scale: curved.value,
                                      child: Opacity(
                                        opacity: animation.value,
                                        child: Dialog(
                                          insetPadding: const EdgeInsets.symmetric(horizontal: 32),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(22),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(22),
                                            child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Animated Icon
                                                Transform.scale(
                                                  scale: 0.85 + curved.value * 0.15,
                                                  child: Container(
                                                    padding: const EdgeInsets.all(16),
                                                    decoration: BoxDecoration(
                                                      color: Colors.red.withValues(alpha: 0.12), // ✅ FIXED
                                                      shape: BoxShape.circle,
                                                    ),
                                                    child: const Icon(
                                                      Icons.logout_rounded,
                                                      color: Colors.red,
                                                      size: 46,
                                                    ),
                                                  ),
                                                ),

                                                const SizedBox(height: 18),

                                                Text(
                                                  "Logout?",
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),

                                                const SizedBox(height: 8),

                                                Text(
                                                  "Are you sure you want to log out from FinTrackU?",
                                                  textAlign: TextAlign.center,
                                                  style: GoogleFonts.inter(
                                                    color: Colors.black54,
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),

                                                const SizedBox(height: 24),

                                                Row(
                                                  children: [
                                                    // Cancel Button
                                                    Expanded(
                                                      child: TextButton(
                                                        style: TextButton.styleFrom(
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(14),
                                                            side: const BorderSide(color: Colors.grey),
                                                          ),
                                                        ),
                                                        onPressed: () => Navigator.pop(context, false),
                                                        child: Text(
                                                          "Cancel",
                                                          style: GoogleFonts.inter(
                                                            fontWeight: FontWeight.w600,
                                                            color: Colors.black87,
                                                          ),
                                                        ),
                                                      ),
                                                    ),

                                                    const SizedBox(width: 12),

                                                    // Logout Button
                                                    Expanded(
                                                      child: ElevatedButton(
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: Colors.red,
                                                          foregroundColor: Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(14),
                                                          ),
                                                        ),
                                                        onPressed: () => Navigator.pop(context, true),
                                                        child: Text(
                                                          "Logout",
                                                          style: GoogleFonts.inter(
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );

                                if (!mounted) return; // ✅ FIXED: Guard with mounted check

                                if (confirmed == true) {
                                  await FirebaseAuth.instance.signOut();
                                  if (!mounted) return;
                                  Navigator.pushReplacementNamed(context, '/login');
                                }
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Title
                      Text(
                        'Current Balance',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Balance Display with Glow
                      Container(
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withValues(alpha: 0.25), // ✅ FIXED
                              blurRadius: 30,
                              spreadRadius: 2,
                              offset: const Offset(0, 0),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isBalanceVisible ? 'RM ' : '',
                              style: GoogleFonts.inter(
                                color: Colors.white70,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              displayBalance,
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),

                            // Toggle Button
                            GestureDetector(
                              onTap: () {
                                setState(() {
                                  _isBalanceVisible = !_isBalanceVisible;
                                });
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(left: 12),
                                child: Icon(displayIcon, color: Colors.white70, size: 20),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Loading indicator
                      if (balanceSnapshot.connectionState == ConnectionState.waiting)
                        const Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white70,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- WIDGET 2: Quick Actions ---
  Widget _quickActions(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, 5)) // ✅ FIXED
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
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
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
                BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 4)) // ✅ FIXED
              ],
            ),
            child: Icon(icon, size: 26, color: iconColor),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: primaryBlue,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }

  // --- WIDGET 3: Current Month's Spending Summary Card ---
  Widget _currentSpendingCard(BuildContext context) {
    return StreamBuilder<double>(
      stream: _getTotalExpensesStream(),
      builder: (context, snapshot) {
        final currentSpending = snapshot.data ?? 0.0;
        final budgetGoal = _monthlyBudgetGoal;

        final progress = min(currentSpending / budgetGoal, 1.0);

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
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 4)) // ✅ FIXED
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This Month\'s Spending',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color:  Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 10),

                // Spending Amount
                Text(
                  'RM ${currentSpending.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: spendingRed,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 15),

                // Progress Bar
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                  minHeight: 10,
                ),
                const SizedBox(height: 8),

                // Details and Goal
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}% of budget used',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: progressColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      'Goal: RM ${budgetGoal.toStringAsFixed(2)}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: Colors.black54,
                        fontWeight: FontWeight.w400,
                      ),
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
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: cardGradientEnd,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
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
    // If the user isn't logged in, show a simple placeholder and allow navigation to login.
    if (_user == null) {
      return Scaffold(
        body: Center(
          child: ElevatedButton(
            onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
            child: Text('Login to view dashboard', style: GoogleFonts.inter()),
          ),
        ),
      );
    }

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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Text(
                        'Additional Tips',
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                          letterSpacing: 0.3,
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

        // --- Floating Chat Button (Positioned at the bottom right) ---
        Positioned(
          right: 20,
          bottom: 20,
          child: FloatingActionButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => AIFinanceAssistant()),
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
        color: const Color(0xEBFFFFFF),
        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: const Color(0x14000000),
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
                    color: const Color(0x5911355F),
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
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? Colors.white : Colors.black54,
                letterSpacing: 0.2,
              ),
              child: Text(label),
            )
          ],
        ),
      ),
    );
  }
}