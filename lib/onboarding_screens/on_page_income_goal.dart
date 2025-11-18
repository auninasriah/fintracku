// on_page_income_goal.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../onboarding_page.dart'; // PASTI PATH BETUL

// DEFINISI FUNGSI UTILITY TYPE
typedef IllustrationAreaBuilder = Widget Function(IconData icon, String title);
typedef VibrantCardTextFieldBuilder = Widget Function({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType,
});
typedef GoalCardBuilder = Widget Function(String title);
typedef GoalSetter = void Function(String? newGoal); // Setter type

class OnPageIncomeGoal extends StatelessWidget {
  final TextEditingController incomeController;
  final String? goal; // State
  final GoalSetter setGoal; // Setter
  final IllustrationAreaBuilder buildIllustrationArea; // Utility 1
  final VibrantCardTextFieldBuilder buildVibrantCardTextField; // Utility 2
  final GoalCardBuilder buildGoalCardForVibrantTheme; // Utility 3

  const OnPageIncomeGoal({
    super.key,
    required this.incomeController,
    required this.goal,
    required this.setGoal,
    required this.buildIllustrationArea,
    required this.buildVibrantCardTextField,
    required this.buildGoalCardForVibrantTheme,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildIllustrationArea(LucideIcons.banknote, 'Financial Goals'),
          const SizedBox(height: 30),
          const Text(
            'Monthly Income (MYR)',
            style: TextStyle(
                color: accentPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          // Panggil fungsi utility yang dihantar
          buildVibrantCardTextField(
            controller: incomeController,
            label: 'Monthly Income',
            icon: LucideIcons.wallet,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 40),
          const Text(
            'What is your main goal?',
            style: TextStyle(
                color: accentPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 15),
          Wrap(
            spacing: 15,
            runSpacing: 15,
            children: [
              buildGoalCardForVibrantTheme('Save'),
              buildGoalCardForVibrantTheme('Invest'),
              buildGoalCardForVibrantTheme('Debt Reduction'),
              buildGoalCardForVibrantTheme('Retirement'),
            ],
          ),
        ],
      ),
    );
  }
}