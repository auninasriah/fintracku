import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'add_expenses_page.dart';

// --- Extension for mapIndexed (Required Fix) ---
extension IterableMapIndexed<E> on Iterable<E> {
  /// Maps each element and its index to a new value.
  Iterable<T> mapIndexed<T>(T Function(int index, E element) f) {
    var index = 0;
    return map((e) => f(index++, e));
  }
}

// --- Improved Color Definitions ---
const Color _primary = Color(0xFF11355F); // Dark Blue (for primary elements)
const Color _accentRed = Color(0xFFE57373); // Red/Pink (for expenses, negative)
const Color _softBg = Color(0xFFF7F9FC); // Light background
const Color _cardBg = Colors.white; // Pure white for cards

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final CollectionReference expensesCol = FirebaseFirestore.instance
      .collection('users')
      .doc('local_user') // 🔁 replace with auth UID later
      .collection('expenses');

  final DocumentReference userDoc = FirebaseFirestore.instance
      .collection('users')
      .doc('local_user'); // 🔁 replace with auth UID later

  DateTime displayedMonth = DateTime.now();

  // Helper: Month name
  static String monthName(DateTime d) => DateFormat('MMMM yyyy').format(d);

  // Helper: Remove time from DateTime
  DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);

  // Helper: Days in a month
  List<int> _daysInMonth(DateTime m) {
    final last = DateTime(m.year, m.month + 1, 0);
    return List<int>.generate(last.day, (i) => i + 1);
  }

  // --- Utility Widgets ---

  // 1. UPDATED: Custom Info Card with Gradient (Red/Blue themed for Expense Tracker)
  Widget _infoCard(String title, String value,
      {required Color startColor, required Color endColor, required Color valueColor}) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4.0),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            // Using a single color background for a cleaner, flatter look, similar to the income tracker
            colors: [startColor, endColor],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: startColor.withOpacity(0.3),
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
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: valueColor, // Value color is white inside the card
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Day strip widget extracted and improved (No changes needed, design is fine)
  Widget _buildDayStrip(
      List<int> days, Set<int> daysWithExpenses, Map<DateTime, List<QueryDocumentSnapshot>> byDate) {
    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey.shade100),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      height: 75,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: days.length,
        itemBuilder: (context, idx) {
          final day = days[idx];
          final isActiveDay = day == DateTime.now().day &&
              displayedMonth.month == DateTime.now().month &&
              displayedMonth.year == DateTime.now().year;
          final hasDot = daysWithExpenses.contains(day);

          final dayOfWeek =
              DateFormat('EEE').format(DateTime(displayedMonth.year, displayedMonth.month, day));

          return GestureDetector(
            onTap: () {
              final dt = DateTime(displayedMonth.year, displayedMonth.month, day);
              _openCalendarModal(context, dt, byDate);
            },
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: isActiveDay ? _accentRed.withOpacity(0.1) : Colors.transparent, // Highlight with expense color
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(dayOfWeek.substring(0, 1), // First letter of the day
                      style: TextStyle(
                          fontSize: 10, color: isActiveDay ? _accentRed : Colors.grey)), // Use accent color
                  const SizedBox(height: 4),
                  Text("$day",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: isActiveDay ? _accentRed : Colors.black87)), // Use accent color
                  const SizedBox(height: 4),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                        color: hasDot ? _accentRed : Colors.transparent,
                        shape: BoxShape.circle),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Pie Chart Legend Item (No changes needed, it's already well-designed)
  Widget _buildLegendItem(
      String category, double amount, Color color, double total) {
    final percentage = total > 0 ? (amount / total * 100) : 0.0;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              category,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 12),
          Text(
            'RM ${amount.toStringAsFixed(2)}',
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _accentRed),
          ),
        ],
      ),
    );
  }

  // --- Category Color and Icon mapping (No changes needed) ---
  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drink':
        return Colors.teal.shade400;
      case 'transport':
        return Colors.blue.shade400;
      case 'bills':
        return Colors.orange.shade400;
      case 'shopping':
        return Colors.purple.shade400;
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
        return Icons.fastfood;
      case 'transport':
        return Icons.directions_car;
      case 'bills':
        return Icons.receipt_long;
      case 'shopping':
        return Icons.shopping_bag;
      case 'health':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'entertainment':
        return Icons.movie;
      default:
        return Icons.category;
    }
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(displayedMonth);

    return Scaffold(
      backgroundColor: _softBg,
      appBar: AppBar(
        backgroundColor: _primary, // Use primary color for the AppBar
        elevation: 0,
        shadowColor: Colors.transparent,
        centerTitle: false, // Title is aligned left

        // Back Button in White
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),

        // Title in White
        title: const Text(
          "Expenses Tracker",
          style: TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: expensesCol.orderBy('date', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docsAll = snap.data?.docs ?? [];
          final docsThisMonth = docsAll.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final ts = data['date'];
            if (ts == null) return false;
            DateTime date =
                ts is Timestamp ? ts.toDate() : DateTime.tryParse(ts.toString()) ?? DateTime.now();
            return date.year == displayedMonth.year &&
                date.month == displayedMonth.month;
          }).toList();

          final Map<String, double> categoryTotals = {};
          final Map<DateTime, List<QueryDocumentSnapshot>> byDate = {};
          double totalExpenses = 0;

          for (var doc in docsAll) {
            final data = doc.data() as Map<String, dynamic>;
            // FIX: Ensure amount is treated as double, Firebase usually stores numbers as num.
            final amount = (data['amount'] is num ? data['amount'].toDouble() : 0.0);
            final category = (data['category'] ?? 'Others').toString();
            final ts = data['date'];
            DateTime date = ts is Timestamp
                ? ts.toDate()
                : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now();

            if (date.year == displayedMonth.year &&
                date.month == displayedMonth.month) {
              categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
              totalExpenses += amount;
            }

            final key = _strip(date);
            byDate.putIfAbsent(key, () => []).add(doc);
          }

          final daysWithExpenses = docsThisMonth.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final ts = data['date'];
            final date = ts is Timestamp
                ? ts.toDate()
                : DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now();
            return date.day;
          }).toSet();
          
          // Generate PieChartSectionData
          final pieSections = categoryTotals.entries
              .mapIndexed(
                (i, e) => PieChartSectionData(
                  value: e.value,
                  color: _categoryColor(e.key),
                  radius: 12, // Reduced radius for a modern, compact doughnut chart
                  showTitle: false, // Don't show text titles on the slices
                  titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              )
              .toList();

          if (docsThisMonth.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.money_off,
                        size: 80, color: _accentRed.withOpacity(0.5)),
                    const SizedBox(height: 16),
                    Text(
                      "All clear! No expenses recorded for ${monthName(displayedMonth)}.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            );
          }

          // Wrap the main content in a Column to allow for the AppBar style
          return Column(
            children: [
              // Month Navigation Bar integrated under the AppBar area (using the same color)
              Container(
                color: _primary, // Extend the primary color down
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      monthName(displayedMonth),
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              displayedMonth = DateTime(
                                  displayedMonth.year, displayedMonth.month - 1, 1);
                            });
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white),
                          onPressed: () {
                            setState(() {
                              displayedMonth = DateTime(
                                  displayedMonth.year, displayedMonth.month + 1, 1);
                            });
                          },
                        ),
                      ],
                    )
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  // Padding diselaraskan untuk memberi ruang pada keseluruhan elemen
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 2. Info Cards (Total Expense & Categories)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _infoCard(
                            "Total Expense",
                            "RM ${totalExpenses.toStringAsFixed(2)}",
                            startColor: _accentRed, // Red gradient for Total Expense
                            endColor: const Color(0xFFC62828),
                            valueColor: Colors.white,
                          ),
                          _infoCard(
                            "Categories",
                            "${categoryTotals.length}",
                            startColor: Colors.blue.shade600, // Different color for a visual break
                            endColor: Colors.blue.shade900,
                            valueColor: Colors.white,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Day Strip (Calendar/Day Overview)
                      _buildDayStrip(days, daysWithExpenses, byDate),
                      const SizedBox(height: 24), // Spacing antara elemen

                      // 4. Pie Chart and Legend Container
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
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: _primary)), // Increased font size for better hierarchy
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 200,
                              child: Row(
                                children: [
                                  // MODIFIED: Doughnut Chart
                                  Expanded(
                                    flex: 1,
                                    child: totalExpenses > 0
                                        ? Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              PieChart(
                                                PieChartData(
                                                  sections: pieSections,
                                                  centerSpaceRadius: 60, // Large center space for doughnut look
                                                  sectionsSpace: 4, // Spacing between slices for modern look
                                                  startDegreeOffset: 270,
                                                ),
                                              ),
                                              // Centered Text
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
                                                        fontSize: 18,
                                                        color: _accentRed), // Highlight expense total with red
                                                  ),
                                                ],
                                              ),
                                            ],
                                          )
                                        : const Center(child: Text("No Data")),
                                  ),
                                  const SizedBox(width: 16),
                                  // Legend
                                  Expanded(
                                    flex: 2,
                                    child: SingleChildScrollView(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: categoryTotals.entries
                                            .map((e) => _buildLegendItem(
                                                e.key,
                                                e.value,
                                                _categoryColor(e.key),
                                                totalExpenses))
                                            .toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24), // Spacing antara elemen

                      // 5. Recent Expenses List
                      const Text("Recent Expenses",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18, color: _primary)),
                      const SizedBox(height: 8),
                      Column(
                        children: docsThisMonth.map((doc) {
                          final d = doc.data() as Map<String, dynamic>;
                          final date = (d['date'] is Timestamp)
                              ? (d['date'] as Timestamp).toDate()
                              : DateTime.tryParse(d['date']?.toString() ?? '') ?? DateTime.now();
                          final category = d['category'] ?? 'Others';
                          final amount = (d['amount'] is num ? d['amount'].toDouble() : 0.0);
                          final note = d.containsKey('note') && d['note'].toString().isNotEmpty
                              ? d['note']
                              : "No notes";

                          final categoryColor = _categoryColor(category.toString());

                          return Card(
                            color: _cardBg,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              contentPadding:
                                  const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: categoryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(_categoryIcon(category.toString()),
                                    color: categoryColor),
                              ),
                              title: Text(category.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold, fontSize: 15)),
                              subtitle: Text(
                                "${DateFormat('dd MMM').format(date)} | $note",
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "- RM ${amount.toStringAsFixed(2)}",
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: _accentRed,
                                        fontSize: 15),
                                  ),
                                  const SizedBox(width: 8),
                                  // More options menu (Edit/Delete)
                                  PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert, color: Colors.grey),
                                    onSelected: (String result) async {
                                      if (result == 'edit') {
                                        if (!mounted) return;
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddExpensePage(
                                                existingId: doc.id, existingData: d),
                                          ),
                                        );
                                      } else if (result == 'delete') {
                                        await expensesCol.doc(doc.id).delete();
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                              content: Text('Expense deleted successfully')),
                                        );
                                      }
                                    },
                                    itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                                      const PopupMenuItem<String>(
                                        value: 'edit',
                                        child: Row(
                                          children: [
                                            Icon(Icons.edit, color: Colors.blue),
                                            SizedBox(width: 8),
                                            Text('Edit'),
                                          ],
                                        ),
                                      ),
                                      const PopupMenuItem<String>(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Delete'),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 80), // Padding for FAB
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: _accentRed, // Use accent red for the expense FAB
        onPressed: () {
          Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AddExpensePage()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  // ================= Calendar modal (No changes needed, design is already good) =================
  Future<void> _openCalendarModal(
      BuildContext context,
      DateTime initialDate,
      Map<DateTime, List<QueryDocumentSnapshot>> byDate) async {
    DateTime selected = initialDate;
    await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: _cardBg,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx2, setStateModal) {
            final entries = byDate[_strip(selected)] ?? [];
            double totalDayExpense = entries.fold(0.0, (sum, doc) {
              final data = doc.data() as Map<String, dynamic>;
              // FIX: Ensure amount is double
              return sum + (data['amount'] is num ? data['amount'].toDouble() : 0.0);
            });

            return Padding(
              padding:
                  EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
              child: SizedBox(
                height: MediaQuery.of(ctx2).size.height * 0.75,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                        width: 48,
                        height: 4,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 12),
                    CalendarDatePicker(
                        initialDate: selected,
                        firstDate: DateTime(2022),
                        lastDate: DateTime(2030),
                        onDateChanged: (d) {
                          setStateModal(() {
                            selected = d;
                          });
                        }),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(DateFormat('dd MMM yyyy').format(selected),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: _primary)),
                              Text("Total: RM ${totalDayExpense.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: _accentRed)),
                            ],
                          ),
                          const Spacer(),
                          ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: _primary,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10))),
                              onPressed: () => Navigator.of(ctx2).pop(),
                              icon: const Icon(Icons.close,
                                  size: 18, color: Colors.white),
                              label: const Text("Close",
                                  style: TextStyle(color: Colors.white)))
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: entries.isEmpty
                          ? Center(
                              child: Text("No expenses on this date",
                                  style: TextStyle(color: Colors.grey.shade600)))
                          : ListView(
                              padding: const EdgeInsets.all(12),
                              children: entries.map((doc) {
                                final d = doc.data() as Map<String, dynamic>;
                                final amount = (d['amount'] is num ? d['amount'].toDouble() : 0.0);
                                final cat = d['category'] ?? 'Others';
                                final note = d['note'] ?? '';
                                final categoryColor =
                                    _categoryColor(cat.toString());

                                return Card(
                                  color: _softBg,
                                  elevation: 0.5,
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor: categoryColor,
                                      child: Icon(_categoryIcon(cat.toString()),
                                          color: Colors.white),
                                    ),
                                    title: Text(cat.toString(),
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(note,
                                        style: const TextStyle(fontSize: 12)),
                                    trailing: Text("- RM ${amount.toStringAsFixed(2)}",
                                        style: const TextStyle(
                                            color: _accentRed,
                                            fontWeight: FontWeight.bold)),
                                  ),
                                );
                              }).toList(),
                            ),
                    ),
                  ],
                ),
              ),
            );
          });
        });
  }
}