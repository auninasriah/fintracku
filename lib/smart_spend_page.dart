import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'smart_spend_main_page.dart';

// Color theme matching your app
const Color primaryBlue = Color(0xFF3C79C1); // Vibrant Light Blue
const Color accentBlue = Color(0xFF2A466F); // Deep Blue
const Color lightAccent = Color(0xFF3F2A61); // Vibrant Purple
const Color softGray = Color(0xFFF2F2F4);
const Color cardGradientStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple

class SmartSpendPage extends StatefulWidget {
  const SmartSpendPage({super.key});

  @override
  State<SmartSpendPage> createState() => _SmartSpendPageState();
}

class _SmartSpendPageState extends State<SmartSpendPage>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late List<AnimationController> _cardControllers;

  final List<Map<String, String>> onboardingQuests = const [
    {
      'title': 'Start Your Budgeting Quest',
      'description': 'Begin your journey to financial stability.',
      'icon': '🧭',
    },
    {
      'title': 'Claim Your Initial Bounty',
      'description': 'Earn Smart Points as a reward for discipline.',
      'icon': '💰',
    },
    {
      'title': 'Beware the Overspending Debuff!',
      'description': 'Avoid penalties by maintaining your budget.',
      'icon': '⚠️',
    },
  ];

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _cardControllers = List.generate(
      onboardingQuests.length,
      (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 200)),
        vsync: this,
      ),
    );

    // Start animations
    _fadeController.forward();
    _slideController.forward();
    for (var controller in _cardControllers) {
      controller.forward();
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildQuestCard(
    String title,
    String desc,
    String icon,
    int index,
  ) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(
        CurvedAnimation(parent: _cardControllers[index], curve: Curves.easeOut),
      ),
      child: FadeTransition(
        opacity: _cardControllers[index],
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            _cardControllers[index].reverse();
          },
          onExit: (_) {
            _cardControllers[index].forward();
          },
          child: AnimatedBuilder(
            animation: _cardControllers[index],
            builder: (context, child) {
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cardGradientStart,
                      cardGradientEnd,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withValues(alpha: 0.15),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 36)),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              desc,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.white.withValues(alpha: 0.8),
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  void _navigateToMain() async {
  // Mark user as having seen onboarding
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'hasSeenSmartSpendOnboarding': true});
  }
  
  if (!mounted) return;
  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => const SmartSpendMainPage()),
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGray,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeController,
          child: Column(
            children: [
              // Minimalist Header
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.5),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 32,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: primaryBlue.withValues(alpha: 0.6),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Smart Spend Hub',
                        style: GoogleFonts.inter(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: primaryBlue,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Master your finances with intelligent tracking',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.black.withValues(alpha: 0.5),
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Quest Cards
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: onboardingQuests.length,
                  itemBuilder: (context, index) {
                    final quest = onboardingQuests[index];
                    return _buildQuestCard(
                      quest['title']!,
                      quest['description']!,
                      quest['icon']!,
                      index,
                    );
                  },
                ),
              ),

              // CTA Button with animation
              ScaleTransition(
                scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                  CurvedAnimation(
                    parent: _fadeController,
                    curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 24,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _navigateToMain,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [cardGradientStart, cardGradientEnd],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: cardGradientStart.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Text(
                          'Get Started',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
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