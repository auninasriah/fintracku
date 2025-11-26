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
      padding: const EdgeInsets.all(26),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Monthly Income",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: incomeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: "Enter your income (MYR)",
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 30),

            const Text(
              "Choose your main goal",
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 14),

            Wrap(
              spacing: 10,
              children: [
                _buildChip("Save"),
                _buildChip("Invest"),
                _buildChip("Debt Reduction"),
                _buildChip("Retirement"),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChip(String text) {
    final bool isSelected = currentGoal == text;

    return ChoiceChip(
      label: Text(text),
      selected: isSelected,
      onSelected: (bool selected) {
        if (selected) onGoalSelected(text);
      },
      selectedColor: Colors.blueAccent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }
}
