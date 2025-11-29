import 'package:flutter/material.dart';

class OnPageIncomeGoal extends StatelessWidget {
  final TextEditingController incomeController;
  final String? currentGoal;
  final ValueChanged<String?> onGoalSelected;

  const OnPageIncomeGoal({
    super.key,
    required this.incomeController,
    required this.currentGoal,
    required this.onGoalSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ---------- Title ----------
          const Text(
            "Monthly income",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "This helps us customise your journey",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 26),

          // ---------- Income Input ----------
          _incomeCard(),

          const SizedBox(height: 36),

          const Text(
            "Your main goal",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 18),

          // ---------- Goal Interest Grid ----------
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 22,
            crossAxisSpacing: 22,
            children: [
              _goalItem(
                label: "Save",
                icon: Icons.account_balance_wallet_rounded,
              ),
              _goalItem(
                label: "Invest",
                icon: Icons.trending_up_rounded,
              ),
              _goalItem(
                label: "Debt",
                icon: Icons.credit_card_rounded,
              ),
              _goalItem(
                label: "Retire",
                icon: Icons.emoji_events_rounded,
              ),
              _goalItem(
                label: "Budget",
                icon: Icons.pie_chart_rounded,
              ),
              _goalItem(
                label: "Grow",
                icon: Icons.auto_graph_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------- Income Card ----------
  Widget _incomeCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: TextField(
        controller: incomeController,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          prefixText: "MYR  ",
          hintText: "0.00",
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  // ---------- Goal Interest Item ----------
  Widget _goalItem({
    required String label,
    required IconData icon,
  }) {
    final bool selected = currentGoal == label;

    return GestureDetector(
      onTap: () => onGoalSelected(label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? Colors.blueAccent.withOpacity(0.12)
              : Colors.grey.shade100,
          border: Border.all(
            color: selected ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: selected
                      ? Colors.blueAccent
                      : Colors.blueAccent.withOpacity(0.25),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 26,
                  ),
                ),

                // ✅ Selected check
                if (selected)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: Colors.white,
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: selected ? Colors.blueAccent : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
