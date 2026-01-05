import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_income_page.dart';

// PDF creation
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Colors
const Color primaryBlue = Color(0xFF3C79C1); // Vibrant Light Blue
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple
const Color cardGradientStart = Color(0xFF3C79C1);
const Color incomeGreen = Color(0xFF4CAF50);
const Color _softBg = Color(0xFFF7F9FC);
const Color _cardBg = Colors.white;

// --- Extension for mapIndexed ---
extension IterableMapIndexed<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) sync* {
    var index = 0;
    for (final element in this) {
      yield f(index++, element);
    }
  }
}

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  late CollectionReference incomes;
  bool _isAuthReady = false;
 
  @override
  void initState() {
    super.initState();
    _initializeFirestore();
  }

  /// Initialize Firestore reference with proper auth checking
  void _initializeFirestore() {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('🔍 IncomePage initState: user = ${user?.uid}');

    if (user == null) {
      debugPrint('⚠️ User not authenticated in IncomePage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be signed in to view income'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      return;
    }

    // Initialize reference to users/{uid}/income (matches home_page.dart)
    incomes = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('income');

    debugPrint('✅ IncomePage Firestore path initialized: users/${user.uid}/income');
    setState(() => _isAuthReady = true);
  }

  // Default selected month
  String selectedMonth = _getMonthName(DateTime.now().month);

  static String _getMonthName(int month) {
    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    return months[month - 1];
  }

  static int _monthNumber(String name) {
    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    return months.indexOf(name) + 1;
  }

  // Category icons
  IconData _iconFor(String category) {
    switch (category.toLowerCase()) {
      case "salary":
        return Icons.account_balance;
      case "allowance":
        return Icons.child_care;
      case "bonus":
        return Icons.military_tech;
      case "part time job":
        return Icons.work;
      case "freelance":
        return Icons.laptop_mac;
      default:
        return Icons.wallet;
    }
  }

  // Chart color
  Color _chartColor(String category) {
    switch (category.toLowerCase()) {
      case 'allowance':
        return Colors.orange;
      case 'part time job':
        return Colors.blue;
      case 'bonus':
        return Colors.deepPurple;
      case 'salary':
        return Colors.yellow.shade700;
      case 'freelance':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  // Convert Flutter Color → PDF Int
  int _pdfColor(Color c) {
    return (c.alpha << 24) | (c.red << 16) | (c.green << 8) | c.blue;
  }

  // PDF generation
  Future<void> _generatePdf(
    List<QueryDocumentSnapshot> docs,
    double total,
    Map<String, double> categories,
  ) async {
    final pdf = pw.Document();

    final tableData = docs.map((d) {
      final data = d.data() as Map<String, dynamic>;
      final amount = (data['amount'] as num).toDouble();
      final date = (data['date'] as Timestamp).toDate();
      return [
        DateFormat('dd MMM yyyy').format(date),
        data['category'],
        "RM ${amount.toStringAsFixed(2)}",
      ];
    }).toList();

    final summaryData = categories.entries.map((e) {
      final pct = (e.value / (total == 0 ? 1 : total)) * 100;
      return [e.key, "RM ${e.value.toStringAsFixed(2)}", "${pct.toStringAsFixed(1)}%"];
    }).toList();

    summaryData.add(["TOTAL", "RM ${total.toStringAsFixed(2)}", "100%"]);

    pdf.addPage(
      pw.Page(
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text("Income Report — $selectedMonth",
                style: pw.TextStyle(
                  fontSize: 20,
                  color: PdfColor.fromInt(_pdfColor(primaryBlue)),
                  fontWeight: pw.FontWeight.bold,
                )),
            pw.SizedBox(height: 20),
            pw.Text("Summary",
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ["Category", "Amount", "Percentage"],
              data: summaryData,
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromInt(_pdfColor(primaryBlue)),
              ),
              headerStyle: pw.TextStyle(
                  color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 25),
            pw.Text("Transactions",
                style:
                    pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),
            pw.TableHelper.fromTextArray(
              headers: ["Date", "Category", "Amount"],
              data: tableData,
            ),
            pw.Spacer(),
            pw.Text(
                "Generated on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}"),
          ],
        ),
      ),
    );

    debugPrint('📄 Generating PDF for $selectedMonth');
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: "income_report_$selectedMonth.pdf",
    );
  }

  /// Show modern calendar with daily summaries
  void _showCalendarView() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CalendarBottomSheet(
        incomes: incomes,
        selectedMonth: selectedMonth,
        chartColor: _chartColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show loading if not authenticated yet
    if (!_isAuthReady) {
      return Scaffold(
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
          title: const Text("Income Tracker",
              style: TextStyle(
                  color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final month = _monthNumber(selectedMonth);
    final year = DateTime.now().year;

    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final stream = incomes
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .orderBy('date', descending: true)
        .snapshots();

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
        title: const Text("Income Tracker",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            tooltip: "View by Calendar",
            onPressed: _showCalendarView,
          ),
          StreamBuilder<QuerySnapshot>(
            stream: stream,
            builder: (_, snap) {
              if (!snap.hasData) return const SizedBox();
              final docs = snap.data!.docs;

              double total = 0;
              final cat = <String, double>{};

              for (var d in docs) {
                final data = d.data() as Map<String, dynamic>;
                final amount = (data['amount'] as num).toDouble();
                final c = data['category'];
                total += amount;
                cat[c] = (cat[c] ?? 0) + amount;
              }

              if (docs.isEmpty) return const SizedBox();

              return IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
                onPressed: () => _generatePdf(docs, total, cat),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add),
        onPressed: () {
          debugPrint('➕ Opening AddIncomePage');
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddIncomePage()),
          );
        },
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            debugPrint('❌ Stream error: ${snapshot.error}');
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final docs = snapshot.data!.docs;

          if (docs.isEmpty) {
            return _noIncomeView();
          }

          // Stats
          double totalIncome = 0;
          final categoryTotals = <String, double>{};

          for (var d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final amount = (data['amount'] as num).toDouble();
            final c = data['category'];

            totalIncome += amount;
            categoryTotals[c] = (categoryTotals[c] ?? 0) + amount;
          }

          final topCategory = categoryTotals.entries
              .reduce((a, b) => a.value > b.value ? a : b);

          // Group transactions by day
          final Map<String, List<QueryDocumentSnapshot>> groupedByDay = {};
          for (var d in docs) {
            final data = d.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final dayKey = DateFormat('yyyy-MM-dd').format(date);
            groupedByDay.putIfAbsent(dayKey, () => []);
            groupedByDay[dayKey]!.add(d);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info boxes - both same size
                Row(
                  children: [
                    Expanded(
                      child: _infoBox(
                        "Total Income",
                        "RM ${totalIncome.toStringAsFixed(2)}",
                        primaryBlue,
                        primaryBlue.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _infoBox(
                        "Top Category",
                        topCategory.key,
                        incomeGreen,
                        incomeGreen.withAlpha((0.7 * 255).round()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                _monthSelector(),
                const SizedBox(height: 25),
                
                // Updated Donut Chart - matching expenses_page
                _donutChart(categoryTotals, totalIncome),
                const SizedBox(height: 28),
                
                const Text("Recent Income",
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Color.fromARGB(255, 0, 0, 0))),
                const SizedBox(height: 12),
                
                // Daily grouped transactions with Dismissible
                ...groupedByDay.entries.map((dayEntry) {
                  final dayKey = dayEntry.key;
                  final dayDocs = dayEntry.value;
                  final displayDate = DateFormat('EEEE, dd MMM')
                      .format(DateTime.parse(dayKey));

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Day header - matching expenses_page style
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: Text(
                          displayDate,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryBlue,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      
                      // Daily transactions with Dismissible
                      ...dayDocs.map((d) {
                        final id = d.id;
                        final data = d.data() as Map<String, dynamic>;
                        final amount = (data['amount'] as num).toDouble();
                        final category = data['category'];
                        final note = data.containsKey('note') && data['note'].toString().isNotEmpty
                            ? data['note']
                            : "No notes";
                        final categoryColor = _chartColor(category);

                        return Dismissible(
                          key: Key(id),
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
                              // Delete
                              return await showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    title: const Text("Confirm Delete"),
                                    content: const Text("Are you sure you want to delete this income?"),
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
                              // Edit
                              if (!mounted) return false;
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddIncomePage(incomeId: id, existingData: data),
                                ),
                              );
                              return false;
                            }
                            return false;
                          },
                          onDismissed: (direction) async {
                            if (direction == DismissDirection.startToEnd) {
                              debugPrint('🗑️ Deleting income: $id');
                              await incomes.doc(id).delete();
                              debugPrint('✅ Income deleted: $id');
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Income deleted successfully')),
                              );
                            }
                          },
                          child: Card(
                            color: _cardBg,
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_iconFor(category), color: categoryColor),
                              ),
                              title: Text(
                                category,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                note,
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              trailing: Text(
                                "+ RM ${amount.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: incomeGreen,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 16),
                    ],
                  );
                }).toList(),
                const SizedBox(height: 80), // Padding for FAB
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoBox(
    String title,
    String value,
    Color a,
    Color b, {
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [a, b]),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold)),
          if (sub != null)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(sub,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 11)),
            ),
        ],
      ),
    );
  }

  Widget _noIncomeView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.money_off, size: 80, color: primaryBlue),
          const SizedBox(height: 10),
          Text("No income recorded for $selectedMonth.",
              style: const TextStyle(
                  fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const AddIncomePage())),
            icon: const Icon(Icons.add_circle, color: primaryBlue),
            label: const Text("Add Income",
                style: TextStyle(color: primaryBlue)),
          ),
        ],
      ),
    );
  }

  Widget _monthSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(12, (i) {
          final m = _getMonthName(i + 1);
          final selected = m == selectedMonth;

          return GestureDetector(
            onTap: () => setState(() => selectedMonth = m),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? primaryBlue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                m,
                style: TextStyle(
                  color: selected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // Updated donut chart - matching expenses_page design
  Widget _donutChart(Map<String, double> categories, double total) {
    final sections = categories.entries.mapIndexed((i, e) {
      return PieChartSectionData(
        value: e.value,
        color: _chartColor(e.key),
        showTitle: false,
        radius: 50, // Match expenses_page radius
      );
    }).toList();

    return Container(
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
          const Text(
            "Income Distribution",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Color.fromARGB(255, 0, 0, 0),
            ),
          ),
          const SizedBox(height: 50),
          Center(
            child: SizedBox(
              height: 185,
              width: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      sections: sections,
                      centerSpaceRadius: 50,
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
                          color: Colors.grey.shade600,
                        ),
                      ),
                      Text(
                        "RM ${total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: incomeGreen,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Dynamic Legend below the chart
          ...categories.entries.map((e) =>
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: _chartColor(e.key),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                  Text(
                    'RM ${e.value.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: incomeGreen,
                    ),
                  ),
                ],
              ),
            ),
          ).toList(),
        ],
      ),
    );
  }
}

/// Modern Calendar Bottom Sheet Widget
class _CalendarBottomSheet extends StatefulWidget {
  final CollectionReference incomes;
  final String selectedMonth;
  final Color Function(String) chartColor;

  const _CalendarBottomSheet({
    required this.incomes,
    required this.selectedMonth,
    required this.chartColor,
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

    final snapshot = await widget.incomes
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
                colors: [primaryBlue, cardGradientEnd],
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
                      "Daily Income Calendar",
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
                        icon: const Icon(Icons.chevron_left, color: primaryBlue),
                        onPressed: _previousMonth,
                      ),
                      Text(
                        DateFormat('MMMM yyyy').format(displayMonth),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right, color: primaryBlue),
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
                          color: primaryBlue,
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
            final hasIncome = dailyTotals.containsKey(date);
            final amount = dailyTotals[date] ?? 0;

            return GestureDetector(
              onTap: hasIncome
                  ? () {
                      Navigator.pop(context);
                    }
                  : null,
              child: Container(
                decoration: BoxDecoration(
                  gradient: hasIncome
                      ? const LinearGradient(
                          colors: [Color(0xFF58C5FF), Color(0xFF7C5CFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: hasIncome ? null : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: hasIncome
                      ? Border.all(color: const Color(0xFF58C5FF), width: 2)
                      : null,
                  boxShadow: hasIncome
                      ? [
                          BoxShadow(
                            color: const Color(0xFF58C5FF)
                                .withAlpha((0.25 * 255).round()),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      '$day',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: hasIncome ? Colors.white : Colors.black87,
                      ),
                    ),
                              if (hasIncome)
                                Padding(
                                  padding: const EdgeInsets.only(top: 2),
                                  child: Flexible(
                                    child: Text(
                                      "RM${amount.toStringAsFixed(0)}",
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  )
                ],
              );
            }
          }