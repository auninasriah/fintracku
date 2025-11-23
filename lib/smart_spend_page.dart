import 'package:flutter/material.dart';
import 'smart_spend_main_page.dart';

class SmartSpendPage extends StatelessWidget {
  const SmartSpendPage({super.key});

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

  // Fungsi Widget Card
  Widget _buildQuestCard(String title, String desc, String icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF006D9C),
            Color(0xFF0099C5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amberAccent, width: 2.2),
        boxShadow: const [
          BoxShadow(
            // shadow color using ARGB hex to avoid withOpacity deprecation
            color: Color(0x59000000),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 40)),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    desc,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Mini progress bar for gamification
                  Container(
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    // Removed `const` so BorderRadius.circular(...) is allowed
                    child: FractionallySizedBox(
                      widthFactor: 0.2, // progress demo
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.amberAccent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    void navigateToNextPage() {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SmartSpendMainPage()),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF00E0FF),
              Color(0xFF00A9D6),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // HERO HEADER
              Padding(
                padding: const EdgeInsets.only(top: 35, bottom: 15),
                child: Column(
                  children: [
                    const Text(
                      "Smart Spend HUB",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [
                          // make Shadow const to allow the outer Text to be const
                          Shadow(
                            blurRadius: 10,
                            color: Colors.black38,
                            offset: Offset(0, 3),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Level 1 • Financial Adventurer",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // POINT BADGE
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF143A66),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(color: Colors.white, width: 1.4),
                        boxShadow: const [
                          BoxShadow(
                            // ARGB hex for ~0.4 opacity on blueAccent
                            color: Color(0x664488FF),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Text(
                        "🏆 100 Smart Points",
                        style: TextStyle(
                          color: Color(0xFFFFEB3B),
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  ],
                ),
              ),

              // LIST OF QUEST CARDS
              Expanded(
                child: ListView(
                  children: onboardingQuests.map((q) {
                    return _buildQuestCard(
                      q['title']!,
                      q['description']!,
                      q['icon']!,
                    );
                  }).toList(),
                ),
              ),

              // GET STARTED BUTTON
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 25),
                child: ElevatedButton(
                  onPressed: navigateToNextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amberAccent,
                    elevation: 12,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(
                          color: Colors.deepOrange, width: 3),
                    ),
                    minimumSize: const Size(double.infinity, 55),
                  ),
                  child: const Text(
                    "START MISSION",
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87),
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