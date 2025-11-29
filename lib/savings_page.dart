import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  // Dummy data - replace with Firebase later
  double currentSaved = 450;
  double savingGoal = 2000;

  final List<Map<String, dynamic>> history = [
    {
      "amount": 120,
      "category": "Emergency",
      "date": DateTime(2024, 11, 10),
      "note": "For rainy days"
    },
    {
      "amount": 80,
      "category": "Travel",
      "date": DateTime(2024, 11, 20),
      "note": "Bali trip"
    },
    {
      "amount": 250,
      "category": "Wedding",
      "date": DateTime(2024, 12, 1),
      "note": "Future planning"
    },
  ];

  // Controllers
  final amountController = TextEditingController();
  final noteController = TextEditingController();

  String selectedCategory = "Emergency";
  DateTime selectedDate = DateTime.now();

  final List<String> categories = [
    "Emergency",
    "Travel",
    "House",
    "Wedding",
    "Car",
    "Education"
  ];

  @override
  Widget build(BuildContext context) {
    double progress = currentSaved / savingGoal;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Savings"),
        backgroundColor: const Color(0xFF11355F),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --------------------------
            //      SAVINGS OVERVIEW
            // --------------------------
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: const Color(0xFF11355F),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  SizedBox(
                    height: 120,
                    width: 120,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 10,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(Colors.white),
                        ),
                        Center(
                          child: Text(
                            "${(progress * 100).toStringAsFixed(0)}%",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "You Saved RM$currentSaved / RM$savingGoal",
                    style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 15,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.2),

            const SizedBox(height: 25),

            // --------------------------
            //   ADD SAVINGS SECTION
            // --------------------------
            const Text(
              "Add Savings",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF11355F)),
            ),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              child: Column(
                children: [
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: "Amount (RM)",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CATEGORY DROPDOWN
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade400),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCategory,
                        items: categories
                            .map((c) => DropdownMenuItem(
                                  value: c,
                                  child: Text(c),
                                ))
                            .toList(),
                        onChanged: (v) {
                          setState(() => selectedCategory = v!);
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // DATE PICKER
                  GestureDetector(
                    onTap: () async {
                      DateTime? picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        initialDate: selectedDate,
                      );
                      if (picked != null) {
                        setState(() => selectedDate = picked);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade400),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(DateFormat("dd MMM yyyy").format(selectedDate)),
                          const Icon(Icons.calendar_month),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: noteController,
                    decoration: InputDecoration(
                      labelText: "Note (optional)",
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),

                  const SizedBox(height: 15),

                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF11355F),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: _addSaving,
                    child: const Text(
                      "Save",
                      style: TextStyle(fontSize: 16),
                    ),
                  )
                ],
              ),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),

            const SizedBox(height: 25),

            // --------------------------
            //   SAVINGS HISTORY
            // --------------------------
            const Text(
              "Savings History",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF11355F)),
            ),
            const SizedBox(height: 10),

            ListView.builder(
              itemCount: history.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, i) {
                final h = history[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 25,
                        backgroundColor: _categoryColor(h["category"]),
                        child: const Icon(Icons.savings, color: Colors.white),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "RM ${h["amount"]}",
                              style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold),
                            ),
                            Text(
                              h["category"],
                              style: const TextStyle(fontSize: 14),
                            ),
                            Text(
                              DateFormat("dd MMM yyyy").format(h["date"]),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.2);
              },
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------
  //   ADD SAVING FUNCTION
  // --------------------------
  void _addSaving() {
    if (amountController.text.isEmpty) return;

    double amount = double.parse(amountController.text);

    setState(() {
      currentSaved += amount;
      history.insert(0, {
        "amount": amount,
        "category": selectedCategory,
        "date": selectedDate,
        "note": noteController.text
      });
    });

    amountController.clear();
    noteController.clear();
  }

  // --------------------------
  //  CATEGORY COLORS (UI)
  // --------------------------
  Color _categoryColor(String cat) {
    switch (cat) {
      case "Emergency":
        return Colors.redAccent;
      case "Travel":
        return Colors.blueAccent;
      case "House":
        return Colors.green;
      case "Wedding":
        return Colors.pinkAccent;
      case "Car":
        return Colors.orange;
      case "Education":
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }
}
