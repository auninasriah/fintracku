import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

const Color primaryBlue = Color(0xFF11355F);
const Color accentBlue = Color(0xFF234A78);

class BudgetPage extends StatelessWidget {
  const BudgetPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        centerTitle: true,
        title: const Text("Budget Settings"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _budgetCard(
              context,
              title: "SET YOUR BUDGET",
              description: "Define your monthly spending limit and track it easily.",
              color: const Color(0xFF5BC0DE),
              icon: Icons.account_balance_wallet_outlined,
              onTap: () => _showSetBudgetDialog(context),
            ),
            const SizedBox(height: 20),
            _budgetCard(
              context,
              title: "MANAGE CATEGORIES",
              description: "Organize spending by category like Food, Transport, Bills, etc.",
              color: const Color(0xFF4B0082),
              icon: Icons.category_outlined,
              onTap: () => _openCategoryList(context),
            ),
            const SizedBox(height: 20),
            _budgetCard(
              context,
              title: "ADD NEW CATEGORY",
              description: "Create a custom category to track specific expenses.",
              color: const Color(0xFFE94E77),
              icon: Icons.add_circle_outline,
              onTap: () => _showAddCategoryDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetCard(
    BuildContext context, {
    required String title,
    required String description,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 60, color: Colors.white),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2);
  }

  void _showSetBudgetDialog(BuildContext context) {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Set Monthly Budget"),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Enter amount (RM)",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _openCategoryList(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CategoryPage()),
    );
  }

  void _showAddCategoryDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text("Add New Category"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "Category Name")),
            const SizedBox(height: 12),
            TextField(
              controller: limitController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Limit (RM)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: accentBlue),
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }
}

class CategoryPage extends StatelessWidget {
  const CategoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final categories = [
      {"icon": Icons.restaurant_menu, "name": "Food", "limit": 400, "color": const Color(0xFF5BC0DE)},
      {"icon": Icons.directions_bus, "name": "Transport", "limit": 200, "color": const Color(0xFF4B0082)},
      {"icon": Icons.receipt_long, "name": "Bills", "limit": 300, "color": const Color(0xFFE94E77)},
      {"icon": Icons.movie, "name": "Entertainment", "limit": 150, "color": const Color(0xFF20B2AA)},
      {"icon": Icons.shopping_bag, "name": "Shopping", "limit": 250, "color": const Color(0xFFF39C12)},
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text("Your Categories"),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentBlue,
        child: const Icon(Icons.add, color: Colors.white),
        onPressed: () {
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, i) {
            final cat = categories[i];
            return Container(
              decoration: BoxDecoration(
                color: cat["color"] as Color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Edit ${cat["name"]} category")),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(cat["icon"] as IconData, color: Colors.white, size: 48),
                    const SizedBox(height: 10),
                    Text(
                      cat["name"] as String,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Limit: RM ${cat["limit"]}",
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.95, 0.95));
          },
        ),
      ),
    );
  }
}
