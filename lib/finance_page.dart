// finance_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- COLOR DEFINITIONS (matching your app theme) ---
const Color primaryBlue = Color(0xFF11355F);
const Color accentBlue = Color(0xFF234A78);
const Color cardGradientStart = Color(0xFF3B8D99);
const Color cardGradientEnd = Color(0xFF4F67B5);
const Color spendingRed = Color(0xFFC62828);
const Color incomeGreen = Color(0xFF4CAF50);
const Color softBg = Color(0xFFF7F9FC);

class FinancePage extends StatefulWidget {
  const FinancePage({super.key});

  @override
  State<FinancePage> createState() => _FinancePageState();
}

class _FinancePageState extends State<FinancePage> {
  late CollectionReference incomeCollection;
  late CollectionReference expensesCollection;
  User? currentUser;

  DateTime selectedMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      incomeCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('income');

      expensesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser!.uid)
          .collection('expenses');
    }
  }

  // Get data for the selected month
  Future<Map<String, double>> _getMonthlyIncomeData() async {
    Map<String, double> dailyData = {};

    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    final snapshot = await incomeCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final amount = (data['amount'] as num).toDouble();

      final dayKey = DateFormat('dd').format(date);
      dailyData[dayKey] = (dailyData[dayKey] ?? 0) + amount;
    }

    return dailyData;
  }

  Future<Map<String, double>> _getMonthlyExpensesData() async {
    Map<String, double> dailyData = {};

    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    final snapshot = await expensesCollection
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: end)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = data['timestamp'] as DateTime;
      final amount = (data['amount'] as num).toDouble();

      final dayKey = DateFormat('dd').format(date);
      dailyData[dayKey] = (dailyData[dayKey] ?? 0) + amount;
    }

    return dailyData;
  }

  Future<double> _getTotalIncome() async {
    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    final snapshot = await incomeCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      total += amount;
    }

    return total;
  }

  Future<double> _getTotalExpenses() async {
    final start = DateTime(selectedMonth.year, selectedMonth.month, 1);
    final end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);

    final snapshot = await expensesCollection
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: end)
        .get();

    double total = 0;
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      total += amount;
    }

    return total;
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        backgroundColor: softBg,
        body: Center(
          child: Text(
            'Please login to view finance summary',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: softBg,
      appBar: AppBar(
        title: Text(
          'Finance Summary',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        backgroundColor: primaryBlue,
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month Selector
            _buildMonthSelector(),

            const SizedBox(height: 24),

            // Summary Cards
            FutureBuilder<List<double>>(
              future: Future.wait([_getTotalIncome(), _getTotalExpenses()]),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final totalIncome = snapshot.data?[0] ?? 0.0;
                final totalExpenses = snapshot.data?[1] ?? 0.0;
                final balance = totalIncome - totalExpenses;

                return Column(
                  children: [
                    _buildSummaryCard(
                      title: 'Total Income',
                      amount: totalIncome,
                      color: incomeGreen,
                      icon: Icons.trending_up,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      title: 'Total Expenses',
                      amount: totalExpenses,
                      color: spendingRed,
                      icon: Icons.trending_down,
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryCard(
                      title: 'Balance',
                      amount: balance,
                      color: balance >= 0 ? incomeGreen : spendingRed,
                      icon: Icons.wallet,
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Income Chart Section
            _buildChartSection(
              title: 'Income by Day',
              futureData: _getMonthlyIncomeData(),
              color: incomeGreen,
            ),

            const SizedBox(height: 28),

            // Expenses Chart Section
            _buildChartSection(
              title: 'Expenses by Day',
              futureData: _getMonthlyExpensesData(),
              color: spendingRed,
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --------------------------
  //   MONTH SELECTOR
  // --------------------------
  Widget _buildMonthSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06), // ✅ FIXED
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Month Button
          IconButton(
            onPressed: () {
              setState(() {
                selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
              });
            },
            icon: const Icon(Icons.chevron_left, color: primaryBlue),
            tooltip: 'Previous Month',
          ),

          // Month Display
          Text(
            DateFormat('MMMM yyyy').format(selectedMonth),
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: primaryBlue,
            ),
          ),

          // Next Month Button
          IconButton(
            onPressed: () {
              if (selectedMonth.month < DateTime.now().month ||
                  selectedMonth.year < DateTime.now().year) {
                setState(() {
                  selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                });
              }
            },
            icon: const Icon(Icons.chevron_right, color: primaryBlue),
            tooltip: 'Next Month',
          ),
        ],
      ),
    );
  }

  // --------------------------
  //   SUMMARY CARDS
  // --------------------------
  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2), // ✅ FIXED
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1), // ✅ FIXED
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15), // ✅ FIXED
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.black54,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'RM ${amount.toStringAsFixed(2)}',
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------
  //   CHART SECTION
  // --------------------------
  Widget _buildChartSection({
    required String title,
    required Future<Map<String, double>> futureData,
    required Color color,
  }) {
    return FutureBuilder<Map<String, double>>(
      future: futureData,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: SizedBox(
              height: 300,
              child: Center(
                child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(color)),
              ),
            ),
          );
        }

        final data = snapshot.data ?? {};

        if (data.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Icon(Icons.bar_chart_outlined, size: 60, color: Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No data for this month',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          );
        }

        // Convert data to chart format
        final chartData = _convertToChartData(data);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06), // ✅ FIXED
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 280,
                child: BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    // ✅ FIXED: Removed duplicate 'barGroups' parameter
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getInterval(chartData),
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withValues(alpha: 0.2), // ✅ FIXED
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final day = (value.toInt() + 1).toString().padLeft(2, '0');
                            return Text(
                              day,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: Colors.black54,
                              ),
                            );
                          },
                          interval: _getChartInterval(data.length),
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              'RM${value.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                color: Colors.black54,
                              ),
                            );
                          },
                          interval: _getInterval(chartData),
                        ),
                      ),
                      topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    maxY: _getMaxY(chartData),
                    barGroups: chartData, // ✅ FIXED: Now only one 'barGroups' parameter
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Statistics
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatistic(
                    label: 'Total',
                    value: 'RM ${_calculateTotal(data).toStringAsFixed(2)}',
                    color: color,
                  ),
                  _buildStatistic(
                    label: 'Average',
                    value: 'RM ${_calculateAverage(data).toStringAsFixed(2)}',
                    color: color,
                  ),
                  _buildStatistic(
                    label: 'Max',
                    value: 'RM ${_calculateMax(data).toStringAsFixed(2)}',
                    color: color,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // --------------------------
  //   HELPER METHODS
  // --------------------------

  List<BarChartGroupData> _convertToChartData(Map<String, double> data) {
    final days = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;

    List<BarChartGroupData> barGroups = [];

    for (int i = 1; i <= days; i++) {
      final dayKey = i.toString().padLeft(2, '0');
      final value = data[dayKey] ?? 0.0;

      barGroups.add(
        BarChartGroupData(
          x: i - 1,
          barRods: [
            BarChartRodData(
              toY: value,
              color: _getBarColor(value, data),
              width: 6,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
            ),
          ],
        ),
      );
    }

    return barGroups;
  }

  Color _getBarColor(double value, Map<String, double> data) {
    final maxValue = data.values.isEmpty ? 1 : data.values.reduce((a, b) => a > b ? a : b);
    final percentage = value / maxValue;

    if (data.values.toList()[0] == spendingRed.value) {
      return spendingRed.withValues(alpha: 0.5 + (percentage * 0.5)); // ✅ FIXED
    } else {
      return incomeGreen.withValues(alpha: 0.5 + (percentage * 0.5)); // ✅ FIXED
    }
  }

  double _getMaxY(List<BarChartGroupData> barGroups) {
    double maxY = 0;
    for (var group in barGroups) {
      for (var rod in group.barRods) {
        if (rod.toY > maxY) maxY = rod.toY;
      }
    }
    return maxY * 1.2; // Add 20% padding
  }

  double _getInterval(List<BarChartGroupData> barGroups) {
    final maxY = _getMaxY(barGroups);
    if (maxY <= 100) return 20;
    if (maxY <= 500) return 100;
    if (maxY <= 1000) return 200;
    if (maxY <= 5000) return 500;
    return 1000;
  }

  double _getChartInterval(int dataLength) {
    if (dataLength <= 7) return 1;
    if (dataLength <= 14) return 2;
    if (dataLength <= 30) return 3;
    return 5;
  }

  double _calculateTotal(Map<String, double> data) {
    return data.values.fold(0, (sum, value) => sum + value);
  }

  double _calculateAverage(Map<String, double> data) {
    if (data.isEmpty) return 0;
    return _calculateTotal(data) / data.length;
  }

  double _calculateMax(Map<String, double> data) {
    if (data.isEmpty) return 0;
    return data.values.reduce((a, b) => a > b ? a : b);
  }

  Widget _buildStatistic({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Colors.black54,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}