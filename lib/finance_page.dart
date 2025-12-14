// finance_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

// --- COLOR DEFINITIONS (matching your app theme) ---
const Color primaryBlue = Color(0xFF3C79C1); // Vibrant Light Blue
const Color accentBlue = Color(0xFF2A466F); // Deep Blue
const Color cardGradientStart = Color(0xFF3C79C1);
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple
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
  int selectedYear = DateTime.now().year;
  bool _showYearView = false; // Toggle between month and year view

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

  // Get yearly data (by month)
  Future<Map<String, double>> _getYearlyIncomeData() async {
    Map<String, double> monthlyData = {};

    final start = DateTime(selectedYear, 1, 1);
    final end = DateTime(selectedYear + 1, 1, 1);

    final snapshot = await incomeCollection
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final amount = (data['amount'] as num).toDouble();

      final monthKey = DateFormat('MM').format(date);
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + amount;
    }

    return monthlyData;
  }

  Future<Map<String, double>> _getYearlyExpensesData() async {
    Map<String, double> monthlyData = {};

    final start = DateTime(selectedYear, 1, 1);
    final end = DateTime(selectedYear + 1, 1, 1);

    final snapshot = await expensesCollection
        .where('timestamp', isGreaterThanOrEqualTo: start)
        .where('timestamp', isLessThan: end)
        .get();

    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = data['timestamp'] as DateTime;
      final amount = (data['amount'] as num).toDouble();

      final monthKey = DateFormat('MM').format(date);
      monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + amount;
    }

    return monthlyData;
  }

  Future<double> _getTotalIncome() async {
    DateTime start, end;

    if (_showYearView) {
      start = DateTime(selectedYear, 1, 1);
      end = DateTime(selectedYear + 1, 1, 1);
    } else {
      start = DateTime(selectedMonth.year, selectedMonth.month, 1);
      end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    }

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
    DateTime start, end;

    if (_showYearView) {
      start = DateTime(selectedYear, 1, 1);
      end = DateTime(selectedYear + 1, 1, 1);
    } else {
      start = DateTime(selectedMonth.year, selectedMonth.month, 1);
      end = DateTime(selectedMonth.year, selectedMonth.month + 1, 1);
    }

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
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [cardGradientStart, cardGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Finance Summary',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 18, color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // View Toggle (Month/Year)
            _buildViewToggle(),

            const SizedBox(height: 16),

            // Month or Year Selector
            _showYearView ? _buildYearSelector() : _buildMonthSelector(),

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
            _showYearView
                ? _buildChartSection(
                    title: 'Income by Month',
                    futureData: _getYearlyIncomeData(),
                    color: incomeGreen,
                    isYearlyView: true,
                  )
                : _buildChartSection(
                    title: 'Income by Day',
                    futureData: _getMonthlyIncomeData(),
                    color: incomeGreen,
                    isYearlyView: false,
                  ),

            const SizedBox(height: 28),

            // Expenses Chart Section
            _showYearView
                ? _buildChartSection(
                    title: 'Expenses by Month',
                    futureData: _getYearlyExpensesData(),
                    color: spendingRed,
                    isYearlyView: true,
                  )
                : _buildChartSection(
                    title: 'Expenses by Day',
                    futureData: _getMonthlyExpensesData(),
                    color: spendingRed,
                    isYearlyView: false,
                  ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --------------------------
  //   VIEW TOGGLE (MONTH/YEAR)
  // --------------------------
  Widget _buildViewToggle() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Month View Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showYearView = false;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: !_showYearView ? primaryBlue : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    bottomLeft: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: !_showYearView ? Colors.white : primaryBlue,
                  ),
                ),
              ),
            ),
          ),
          // Year View Button
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showYearView = true;
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _showYearView ? primaryBlue : Colors.transparent,
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(16),
                    bottomRight: Radius.circular(16),
                  ),
                ),
                child: Text(
                  'Yearly',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: _showYearView ? Colors.white : primaryBlue,
                  ),
                ),
              ),
            ),
          ),
        ],
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
            color: Colors.black.withValues(alpha: 0.06),
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
  //   YEAR SELECTOR
  // --------------------------
  Widget _buildYearSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Previous Year Button
          IconButton(
            onPressed: () {
              setState(() {
                selectedYear -= 1;
              });
            },
            icon: const Icon(Icons.chevron_left, color: primaryBlue),
            tooltip: 'Previous Year',
          ),

          // Year Display
          GestureDetector(
            onTap: () {
              // Open year picker dialog
              _showYearPickerDialog();
            },
            child: Text(
              selectedYear.toString(),
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
          ),

          // Next Year Button
          IconButton(
            onPressed: () {
              if (selectedYear < DateTime.now().year) {
                setState(() {
                  selectedYear += 1;
                });
              }
            },
            icon: const Icon(Icons.chevron_right, color: primaryBlue),
            tooltip: 'Next Year',
          ),
        ],
      ),
    );
  }

  // --------------------------
  //   YEAR PICKER DIALOG
  // --------------------------
  void _showYearPickerDialog() {
    final currentYear = DateTime.now().year;
    final years = List.generate(10, (index) => currentYear - 5 + index);

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Select Year',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 300,
                  child: GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: years.length,
                    itemBuilder: (context, index) {
                      final year = years[index];
                      final isSelected = year == selectedYear;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedYear = year;
                          });
                          Navigator.pop(context);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? primaryBlue : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              year.toString(),
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
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
        border: Border.all(color: color.withValues(alpha: 0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
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
              color: color.withValues(alpha: 0.15),
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
    required bool isYearlyView,
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
                  'No data for this ${isYearlyView ? 'year' : 'month'}',
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
        final chartData = isYearlyView
            ? _convertToYearlyChartData(data)
            : _convertToMonthlyChartData(data);

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
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
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: _getInterval(chartData),
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: Colors.grey.withValues(alpha: 0.2),
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
                            if (isYearlyView) {
                              final monthNames = [
                                'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                                'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
                              ];
                              final index = value.toInt();
                              return index < 12
                                  ? Text(
                                      monthNames[index],
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        color: Colors.black54,
                                      ),
                                    )
                                  : const SizedBox.shrink();
                            } else {
                              final day = (value.toInt() + 1).toString().padLeft(2, '0');
                              return Text(
                                day,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  color: Colors.black54,
                                ),
                              );
                            }
                          },
                          interval: isYearlyView ? 1 : _getChartInterval(data.length),
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
                    barGroups: chartData,
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

  List<BarChartGroupData> _convertToMonthlyChartData(Map<String, double> data) {
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

  List<BarChartGroupData> _convertToYearlyChartData(Map<String, double> data) {
    List<BarChartGroupData> barGroups = [];

    for (int i = 1; i <= 12; i++) {
      final monthKey = i.toString().padLeft(2, '0');
      final value = data[monthKey] ?? 0.0;

      barGroups.add(
        BarChartGroupData(
          x: i - 1,
          barRods: [
            BarChartRodData(
              toY: value,
              color: _getBarColor(value, data),
              width: 8,
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
      return spendingRed.withValues(alpha: 0.5 + (percentage * 0.5));
    } else {
      return incomeGreen.withValues(alpha: 0.5 + (percentage * 0.5));
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