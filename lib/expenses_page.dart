import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'add_expenses_page.dart'; 

// --- Extension for mapIndexed (Fixed Ralat toList) ---
extension IterableMapIndexed<E> on Iterable<E> {
  /// Maps each element and its index to a new value.
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) sync* {
    var index = 0;
    for (final element in this) {
      yield f(index++, element);
    }
  }
}

// --- Improved Color Definitions ---
const Color _primary = Color(0xFF11355F); // Dark Blue (for primary elements)
const Color _accentRed = Color.fromARGB(255, 105, 13, 13); // Red/Pink (for expenses, negative)
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple
const Color cardGradientStart = Color(0xFF3C79C1);
const Color _softBg = Color(0xFFF7F9FC); // Light background
const Color _cardBg = Colors.white; // Pure white for cards
const Color _navy = Color(0xFF0D1B2A); // dark navy for appbar text

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
 
  late CollectionReference expensesCol;

  DateTime displayedMonth = DateTime.now();
  String selectedMonth = _getMonthName(DateTime.now().month);

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
  }

  // Initialize Firestore reference with proper auth checking
  void _initializeFirestore() {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('🔍 ExpensesPage initState: user = ${user?.uid}');

    if (user == null) {
      debugPrint('⚠️ User not authenticated in ExpensesPage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be signed in to view expenses'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      return;
    }

    // Initialize reference to users/{uid}/expenses (matches home_page.dart)
    expensesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses');

    debugPrint('✅ ExpensesPage Firestore path initialized: users/${user.uid}/expenses');
  }

  /// Show modern calendar with daily summaries
  void _showCalendarView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalendarBottomSheet(
        expenses: expensesCol,
        selectedMonth: selectedMonth,
        categoryColor: _categoryColor,
      ),
    );
  }

  // Helper: Month name long
  static String monthName(DateTime d) => DateFormat('MMMM yyyy').format(d);

  // Short month mapping
  static String _getMonthName(int month) {
    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    return months[month - 1];
  }



  // Helper: Remove time from DateTime
  DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);

  // --- Month selector widget (pill style) with glow effect ---
  Widget _buildMonthSelector() {
    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        children: months.mapIndexed((i, m) {
          final bool isSelected = (m == selectedMonth);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  displayedMonth = DateTime(displayedMonth.year, i + 1, 1);
                  selectedMonth = m;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 18),
                decoration: BoxDecoration(
                  color: isSelected ? _primary : Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _primary.withValues(alpha: 0.4),
                            blurRadius: 12,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  m,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : Colors.black87,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // Custom Info Card with Gradient
  Widget _infoCard(String title, String value,
      {required Color startColor, required Color endColor, required Color valueColor}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: startColor.withValues(alpha: 0.18),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Category Color and Icon mapping ---
  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drink':
        return Colors.blue.shade900;
      case 'transport':
        return Colors.blue.shade400;
      case 'bills':
        return Colors.orange.shade400;
      case 'shopping':
        return Colors.yellow.shade700;
      case 'health':
        return Colors.brown.shade400;
      case 'education':
        return Colors.indigo.shade400;
      case 'entertainment':
        return Colors.pink.shade400;
      default:
        return Colors.blueGrey.shade400;
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drink':
        return Icons.restaurant;
      case 'transport':
        return Icons.commute;
      case 'bills':
        return Icons.receipt_long;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.medical_services;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  // Helper to format date for grouping
  String _formatDateForHeader(DateTime date) {
    final now = DateTime.now();
    final today = _strip(now);
    final yesterday = _strip(now.subtract(const Duration(days: 1)));
    final strippedDate = _strip(date);

    if (strippedDate == today) {
      return "Today";
    } else if (strippedDate == yesterday) {
      return "Yesterday";
    } else {
      return DateFormat('dd MMM yyyy').format(date);
    }
  }

  // Build Method
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softBg,
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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Expenses Tracker",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            tooltip: "View by Calendar",
            onPressed: _showCalendarView,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: expensesCol.orderBy('date', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docsAll = snap.data?.docs ?? [];
          final List<QueryDocumentSnapshot> docsThisMonth = [];
          final Map<String, double> categoryTotals = {};
          double totalExpenses = 0;

          // Filter for the displayed month and calculate totals
          for (var doc in docsAll) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['date'];
            if (ts == null) continue;
            DateTime date = ts is Timestamp ? ts.toDate() : DateTime.tryParse(ts.toString()) ?? DateTime.now();

            if (date.year == displayedMonth.year && date.month == displayedMonth.month) {
              docsThisMonth.add(doc);
              final amount = (data['amount'] is num ? data['amount'].toDouble() : 0.0);
              final category = (data['category'] ?? 'Others').toString();
              categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
              totalExpenses += amount;
            }
          }

          // Group expenses by date for the "Recent Expenses" section
          final Map<String, List<QueryDocumentSnapshot>> groupedExpenses = {};
          for (var doc in docsThisMonth) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = data['date'];
            DateTime date = ts is Timestamp ? ts.toDate() : DateTime.tryParse(ts.toString()) ?? DateTime.now();
            final header = _formatDateForHeader(date);
            groupedExpenses.putIfAbsent(header, () => []).add(doc);
          }

          // Sort date headers (Today, Yesterday, then by date descending)
          final List<String> sortedGroupKeys = groupedExpenses.keys.toList();
          sortedGroupKeys.sort((a, b) {
            if (a == "Today") return -1;
            if (b == "Today") return 1;
            if (a == "Yesterday") return -1;
            if (b == "Yesterday") return 1;
            DateTime? dateA = DateFormat('dd MMM yyyy').tryParse(a);
            DateTime? dateB = DateFormat('dd MMM yyyy').tryParse(b);
            if (dateA == null && dateB == null) return 0;
            if (dateA == null) return 1;
            if (dateB == null) return -1;
            return dateB.compareTo(dateA);
          });

          // Generate PieChartSectionData for donut
          final pieSections = categoryTotals.entries.mapIndexed((i, e) {
            return PieChartSectionData(
              value: e.value,
              color: _categoryColor(e.key),
              radius: 50,
              showTitle: false,
            );
          }).toList();

          // If no records this month, show empty state
          if (docsThisMonth.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoCard(
                        "Total Expense",
                        "RM 0.00",
                        startColor: _accentRed,
                        endColor: const Color(0xFFC62828),
                        valueColor: Colors.white,
                      ),
                      _infoCard(
                        "Categories",
                        "0",
                        startColor: Colors.blue.shade600,
                        endColor: Colors.blue.shade900,
                        valueColor: Colors.white,
                      ),
                    ],
                  ),
                ),
                _buildMonthSelector(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.money_off, size: 80, color: _accentRed.withValues(alpha: 0.5)),
                          const SizedBox(height: 16),
                          Text(
                            "All clear! No expenses recorded for ${monthName(displayedMonth)}.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          }

          // Main content when there are expenses
          return Column(
            children: [
              // Info Cards
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoCard(
                      "Total Expense",
                      "RM ${totalExpenses.toStringAsFixed(2)}",
                      startColor: _accentRed,
                      endColor: const Color(0xFFC62828),
                      valueColor: Colors.white,
                    ),
                    _infoCard(
                      "Categories",
                      "${categoryTotals.length}",
                      startColor: Colors.blue.shade600,
                      endColor: Colors.blue.shade900,
                      valueColor: Colors.white,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // Month selector
              _buildMonthSelector(),
              const SizedBox(height: 8),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Donut Chart Container
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Spending Distribution",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18, color: _primary)),
                            const SizedBox(height: 16),
                            Center(
                              child: SizedBox(
                                height: 180, 
                                width: 180,  
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    PieChart(
                                      PieChartData(
                                        sections: pieSections,
                                        centerSpaceRadius: 60, 
                                        sectionsSpace: 4,
                                        startDegreeOffset: 270,
                                      ),
                                    ),
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          "Total",
                                          style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey.shade600),
                                        ),
                                        Text(
                                          "RM ${totalExpenses.toStringAsFixed(2)}",
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 20,
                                              color: _accentRed), 
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Dynamic Legend below the chart
                            ...categoryTotals.entries.map((e) =>
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(color: _categoryColor(e.key), shape: BoxShape.circle),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(e.key, style: const TextStyle(fontSize: 14, color: Colors.black87)),
                                      ),
                                      Text('RM ${e.value.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold, color: _accentRed)), 
                                    ],
                                  ),
                                )
                            ).toList(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Spending Habits Section ---
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.1),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Spending Habits",
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 18, color: _primary)),
                            const SizedBox(height: 12),
                            const SizedBox(height: 8),
                             _buildInsightItem(
                              icon: Icons.info_outline,
                              text: "You have spent RM${(totalExpenses / categoryTotals.length).toStringAsFixed(2)} per category on average.",
                              color: Colors.blue.shade600,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // --- Recent Expenses List (Grouped by Date) ---
                      const Text("Recent Expenses",
                          style:
                              TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: _primary)),
                      const SizedBox(height: 8),

                      // Iterate through sorted grouped expenses
                      ...sortedGroupKeys.expand((header) {
                        final expensesForDate = groupedExpenses[header]!;
                        return [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              header,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _navy,
                              ),
                            ),
                          ),
                          ...expensesForDate.map((doc) {
                            final d = doc.data() as Map<String, dynamic>;
                            final category = d['category'] ?? 'Others';
                            final amount = (d['amount'] is num ? d['amount'].toDouble() : 0.0);
                            final note = d.containsKey('note') && d['note'].toString().isNotEmpty
                                ? d['note']
                                : "No notes";
                            final categoryColor = _categoryColor(category.toString());

                            return Dismissible(
                              key: Key(doc.id),
                              direction: DismissDirection.horizontal,
                              background: Container(
                                color: const Color.fromARGB(255, 82, 15, 10),
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              secondaryBackground: Container(
                                color: Colors.blue,
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(horizontal: 20),
                                child: const Icon(Icons.edit, color: Colors.white),
                              ),
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  return await showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text("Confirm Delete"),
                                        content: const Text("Are you sure you want to delete this expense?"),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(false),
                                            child: const Text("Cancel"),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.of(context).pop(true),
                                            child: const Text("Delete"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else if (direction == DismissDirection.endToStart) {
                                  if (!mounted) return false;
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AddExpensePage(existingId: doc.id, existingData: d),
                                    ),
                                  );
                                  return false;
                                }
                                return false;
                              },
                              onDismissed: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  await expensesCol.doc(doc.id).delete();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Expense deleted successfully')),
                                    );
                                  }
                                }
                              },
                              child: Card(
                                color: _cardBg,
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                elevation: 1,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                child: ListTile(
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                                  leading: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: categoryColor.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(_categoryIcon(category.toString()), color: categoryColor),
                                  ),
                                  title: Text(category.toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  subtitle: Text(note,
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                                  trailing: Text(
                                    "- RM ${amount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold, color: _accentRed, fontSize: 15), 
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ];
                      }).toList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF3C79C1),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpensePage()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // Helper widget for Spending Habits insights
  Widget _buildInsightItem({required IconData icon, required String text, required Color color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14.5, color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

/// Modern Calendar Bottom Sheet Widget for Expenses
class _CalendarBottomSheet extends StatefulWidget {
  final CollectionReference expenses;
  final String selectedMonth;
  final Color Function(String) categoryColor;

  const _CalendarBottomSheet({
    required this.expenses,
    required this.selectedMonth,
    required this.categoryColor,
  });

  @override
  State<_CalendarBottomSheet> createState() => _CalendarBottomSheetState();
}

class _CalendarBottomSheetState extends State<_CalendarBottomSheet> {
  late DateTime displayMonth;
  Map<DateTime, double> dailyTotals = {};

  @override
  void initState() {
    super.initState();
    final monthNum = _monthNumber(widget.selectedMonth);
    displayMonth = DateTime(DateTime.now().year, monthNum, 1);
    _fetchDailyTotals();
  }

  int _monthNumber(String name) {
    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    return months.indexOf(name) + 1;
  }

  Future<void> _fetchDailyTotals() async {
    final start = DateTime(displayMonth.year, displayMonth.month, 1);
    final end = DateTime(displayMonth.year, displayMonth.month + 1, 0, 23, 59, 59);

    final snapshot = await widget.expenses
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
        .get();

    final Map<DateTime, double> totals = {};
    for (var doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final amount = (data['amount'] as num).toDouble();
      final dayKey = DateTime(date.year, date.month, date.day);
      totals[dayKey] = (totals[dayKey] ?? 0) + amount;
    }

    setState(() => dailyTotals = totals);
  }

  void _previousMonth() {
    setState(() {
      displayMonth = DateTime(displayMonth.year, displayMonth.month - 1);
      _fetchDailyTotals();
    });
  }

  void _nextMonth() {
    setState(() {
      displayMonth = DateTime(displayMonth.year, displayMonth.month + 1);
      _fetchDailyTotals();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_primary, Color(0xFF234A78)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Daily Expenses Calendar",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Month Navigation
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left, color: _primary),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(displayMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: _primary),
                        onPressed: _nextMonth,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Calendar Grid
                  _buildCalendarGrid(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(displayMonth.year, displayMonth.month, 1);
    final lastDay = DateTime(displayMonth.year, displayMonth.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday;

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      children: [
        // Day labels
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: dayLabels
              .map((day) => SizedBox(
                    width: MediaQuery.of(context).size.width / 8,
                    child: Center(
                      child: Text(
                        day,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: _primary,
                        ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar days
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
          ),
          itemCount: daysInMonth + firstWeekday - 1,
          itemBuilder: (context, index) {
            if (index < firstWeekday - 1) {
              return const SizedBox();
            }

            final day = index - (firstWeekday - 1) + 1;
            final date = DateTime(displayMonth.year, displayMonth.month, day);
            final hasExpense = dailyTotals.containsKey(date);
            final amount = dailyTotals[date] ?? 0;

            return GestureDetector(
              onTap: hasExpense
                  ? () {
                      Navigator.pop(context);
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  gradient: hasExpense
                      ? const LinearGradient(
                          colors: [Color(0xFF3C79C1), Color(0xFF5A9FD4)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasExpense ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: hasExpense
                      ? Border.all(color: const Color(0xFF3C79C1), width: 2)
                      : null,
                  boxShadow: hasExpense
                      ? [
                          BoxShadow(
                            color: const Color(0xFF3C79C1)
                                .withValues(alpha: 0.25),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasExpense ? Colors.white : Colors.black87,
                      ),
                    ),
                    if (hasExpense)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          "RM ${amount.toStringAsFixed(0)}",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}