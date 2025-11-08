import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'home_page.dart';
import 'add_income_page.dart';

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final CollectionReference incomes = FirebaseFirestore.instance
      .collection('users')
      .doc('local_user')
      .collection('income');

  String selectedMonth = _getMonthName(DateTime.now().month);
  final int _currentIndex = 1; // made final

  static String _getMonthName(int month) {
    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    return months[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Income Tracker",
          style: TextStyle(
              color: Color(0xFF11355F), fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF11355F)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: incomes.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _noIncomeView();
          }

          final docs = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['date'] == null) return false;
            final date = (data['date'] as Timestamp).toDate();
            return _getMonthName(date.month) == selectedMonth;
          }).toList();

          double totalIncome = 0;
          String highestCategory = '';
          double highestAmount = 0;
          Map<String, double> categoryTotals = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0).toDouble();
            final category = data['category'] ?? 'Others';

            totalIncome += amount;
            categoryTotals[category] =
                (categoryTotals[category] ?? 0) + amount;

            if (amount > highestAmount) {
              highestAmount = amount;
              highestCategory = category;
            }
          }

          final pieSections = categoryTotals.entries.map((entry) {
            return PieChartSectionData(
              value: entry.value,
              title: entry.key,
              color: _getCategoryColor(entry.key),
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            );
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Summary Cards
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoCard("Total Income", "RM ${totalIncome.toStringAsFixed(2)}"),
                    _infoCard("Highest Income", highestCategory,
                        subtitle: "RM ${highestAmount.toStringAsFixed(2)}"),
                  ],
                ),
                const SizedBox(height: 24),

                // Month Selector (horizontal scroll)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: List.generate(12, (index) {
                      final month = _getMonthName(index + 1);
                      final isSelected = month == selectedMonth;
                      return GestureDetector(
                        onTap: () => setState(() => selectedMonth = month),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF11355F)
                                : Colors.grey[200],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            month,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.black87,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 20),

                // Pie Chart
                SizedBox(
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sections: pieSections,
                      centerSpaceRadius: 60,
                      sectionsSpace: 3,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Income List
                Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data['category'] ?? 'Others';
                    final amount = (data['amount'] ?? 0).toDouble();
                    final color = _getCategoryColor(category);
                    final date = (data['date'] as Timestamp?)?.toDate();

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      color: color.withValues(alpha: 0.1), // replaced withOpacity
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: const Icon(Icons.wallet, color: Colors.white),
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        subtitle: Text(
                          date != null
                              ? "${date.day}/${date.month}/${date.year}"
                              : "",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => AddIncomePage(
                                      incomeId: doc.id,
                                      existingData: data,
                                    ),
                                  ),
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                incomes.doc(doc.id).delete();
                              },
                            ),
                            Text(
                              "+ RM ${amount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF11355F),
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddIncomePage()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: const Color(0xFF11355F),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const HomePage()));
          } else if (index == 1) {
            // stay here
          } else if (index == 2) {
            // handle expense tab if needed
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.attach_money), label: 'Income'),
          BottomNavigationBarItem(
              icon: Icon(Icons.money_off), label: 'Expense'),
        ],
      ),
    );
  }

  Widget _noIncomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.list_alt_rounded, size: 80, color: Color(0xFF11355F)),
          const SizedBox(height: 16),
          const Text("No Income",
              style: TextStyle(fontSize: 18, color: Colors.black54)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => const AddIncomePage()));
            },
            child: const Text(
              "Set Now",
              style: TextStyle(
                  color: Color(0xFF11355F), fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, {String? subtitle}) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F5F9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          if (subtitle != null)
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 14,
                    color: Colors.green,
                    fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'allowance':
        return Colors.blueAccent;
      case 'part time job':
        return Colors.green;
      case 'bonus':
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }
}