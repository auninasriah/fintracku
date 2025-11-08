import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'home_page.dart'; // for CustomBottomNav + HomePage
import 'add_expense_page.dart'; // Add Expense form

// ================== THEME COLORS ==================
const _primary = Color(0xFF11355F);
const _accent = Color(0xFF234A78);
const _softBg = Color(0xFFF2F5F9);

class ExpensesPage extends StatefulWidget {
  const ExpensesPage({super.key});

  @override
  State<ExpensesPage> createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  // ============== FIREBASE PATH ==============
  final CollectionReference expensesCol = FirebaseFirestore.instance
      .collection('users')
      .doc('local_user') // 🔁 replace with auth UID later
      .collection('expenses');

  DateTime displayedMonth = DateTime.now();
  int _currentIndex = 2; // tab index for bottom nav

  static String monthName(DateTime d) => DateFormat('MMMM yyyy').format(d);
  DateTime _strip(DateTime d) => DateTime(d.year, d.month, d.day);

  List<int> _daysInMonth(DateTime m) {
    final last = DateTime(m.year, m.month + 1, 0);
    return List<int>.generate(last.day, (i) => i + 1);
  }

  @override
  Widget build(BuildContext context) {
    final days = _daysInMonth(displayedMonth);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              monthName(displayedMonth),
              style: const TextStyle(color: _primary, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: _primary),
                  onPressed: () {
                    setState(() {
                      displayedMonth =
                          DateTime(displayedMonth.year, displayedMonth.month - 1, 1);
                    });
                  },
                ),
                Text(
                  'This Month',
                  style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, color: _primary),
                  onPressed: () {
                    setState(() {
                      displayedMonth =
                          DateTime(displayedMonth.year, displayedMonth.month + 1, 1);
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),

      // ========== FIRESTORE STREAM ==========
      body: StreamBuilder<QuerySnapshot>(
        stream: expensesCol.orderBy('date', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docsAll = snap.data?.docs ?? [];

          // filter by month
          final docsThisMonth = docsAll.where((d) {
            final data = d.data() as Map<String, dynamic>;
            final ts = data['date'];
            if (ts == null) return false;
            DateTime date;
            if (ts is Timestamp) {
              date = ts.toDate();
            } else {
              date = DateTime.tryParse(ts.toString()) ?? DateTime.now();
            }
            return date.year == displayedMonth.year &&
                date.month == displayedMonth.month;
          }).toList();

          // totals
          final Map<String, double> categoryTotals = {};
          double totalExpenses = 0;
          final Map<DateTime, List<QueryDocumentSnapshot>> byDate = {};

          for (var doc in docsAll) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0).toDouble();
            final category = (data['category'] ?? 'Others').toString();
            DateTime date;
            final ts = data['date'];
            if (ts is Timestamp) date = ts.toDate();
            else date = DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now();

            if (date.year == displayedMonth.year && date.month == displayedMonth.month) {
              categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
              totalExpenses += amount;
            }

            final key = _strip(date);
            byDate.putIfAbsent(key, () => []).add(doc);
          }

          final Set<int> daysWithExpenses = docsThisMonth.map((d) {
            final data = d.data() as Map<String, dynamic>;
            final ts = data['date'];
            DateTime date =
                (ts is Timestamp) ? ts.toDate() : (DateTime.tryParse(ts?.toString() ?? '') ?? DateTime.now());
            return date.day;
          }).toSet();

          // pie sections
          final pieSections = categoryTotals.entries.mapIndexed((i, e) {
            final color = _categoryColor(e.key);
            return PieChartSectionData(
              value: e.value,
              color: color,
              radius: 56,
              showTitle: false,
            );
          }).toList();

          // ========== UI BODY ==========
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _infoCard("Total Expense", "RM ${totalExpenses.toStringAsFixed(2)}"),
                    _infoCard("Categories", "${categoryTotals.length}"),
                  ],
                ),
                const SizedBox(height: 12),

                // 🗓️ Calendar button
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.calendar_month, color: Colors.white),
                    label: const Text("View Calendar", style: TextStyle(color: Colors.white)),
                    onPressed: () {
                      _openCalendarModal(context, DateTime.now(), byDate);
                    },
                  ),
                ),
                const SizedBox(height: 18),

                // day-strip
                SizedBox(
                  height: 68,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: days.length,
                    itemBuilder: (context, idx) {
                      final day = days[idx];
                      final isActive = day == DateTime.now().day &&
                          displayedMonth.month == DateTime.now().month &&
                          displayedMonth.year == DateTime.now().year;
                      final hasDot = daysWithExpenses.contains(day);
                      return GestureDetector(
                        onTap: () {
                          final dt = DateTime(displayedMonth.year, displayedMonth.month, day);
                          _openCalendarModal(context, dt, byDate);
                        },
                        child: Container(
                          width: 54,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "$day",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive ? _primary : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: hasDot ? _accent : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 18),

                // chart
                SizedBox(
                  height: 190,
                  child: pieSections.isEmpty
                      ? Center(
                          child: Text(
                            "No data to display",
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : PieChart(
                          PieChartData(
                            sections: pieSections,
                            centerSpaceRadius: 40,
                            sectionsSpace: 4,
                            pieTouchData: PieTouchData(
                              touchCallback: (f, p) {},
                            ),
                          ),
                        ),
                ),

                const SizedBox(height: 18),

                // category cards
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: categoryTotals.entries.map((e) {
                    final color = _categoryColor(e.key);
                    return Container(
                      width: (MediaQuery.of(context).size.width - 60) / 2,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text("RM ${e.value.toStringAsFixed(2)}",
                              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 22),

                const Text("Recent", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),

                Column(
                  children: docsThisMonth.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    DateTime date = (d['date'] is Timestamp)
                        ? (d['date'] as Timestamp).toDate()
                        : (DateTime.tryParse(d['date']?.toString() ?? '') ?? DateTime.now());
                    final category = d['category'] ?? 'Others';
                    final amt = (d['amount'] ?? 0).toDouble();
                    final note = d['note'] ?? '';
                    final color = _categoryColor(category.toString());
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        leading: CircleAvatar(
                            backgroundColor: color,
                            child: const Icon(Icons.receipt_long, color: Colors.white)),
                        title: Text(category.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("${DateFormat('dd MMM yyyy').format(date)} • $note"),
                        trailing: Text("RM ${amt.toStringAsFixed(2)}",
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 88),
              ],
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: _primary,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const AddExpensePage()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),

      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
          } else if (i == 1) {
            // Smart Spend (not implemented)
          } else if (i == 2) {
            // Stay here
          } else if (i == 3) {
            // Settings
          }
        },
      ),
    );
  }

  // ================== CALENDAR MODAL ==================
  Future<void> _openCalendarModal(
      BuildContext context, DateTime initialDate, Map<DateTime, List<QueryDocumentSnapshot>> byDate) async {
    DateTime selected = initialDate;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, setModalState) {
          final entries = byDate[_strip(selected)] ?? [];
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(ctx2).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(ctx2).size.height * 0.75,
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                      width: 48,
                      height: 4,
                      decoration:
                          BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 12),
                  CalendarDatePicker(
                    initialDate: selected,
                    firstDate: DateTime(2022),
                    lastDate: DateTime(2030),
                    onDateChanged: (d) {
                      setModalState(() {
                        selected = d;
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        Text(DateFormat('dd MMM yyyy').format(selected),
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                        const Spacer(),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(backgroundColor: _primary),
                          onPressed: () => Navigator.of(ctx2).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text("Close"),
                        )
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
                              final amt = (d['amount'] ?? 0).toDouble();
                              final cat = d['category'] ?? 'Others';
                              final note = d['note'] ?? '';
                              return Card(
                                margin: const EdgeInsets.symmetric(vertical: 6),
                                child: ListTile(
                                  leading: CircleAvatar(
                                      backgroundColor: _categoryColor(cat.toString()),
                                      child: const Icon(Icons.money, color: Colors.white)),
                                  title: Text(cat.toString(),
                                      style: const TextStyle(fontWeight: FontWeight.bold)),
                                  subtitle: Text(note),
                                  trailing: Text("RM ${amt.toStringAsFixed(2)}",
                                      style: const TextStyle(color: Colors.green)),
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
      },
    );
  }

  Widget _infoCard(String title, String value) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: _softBg, borderRadius: BorderRadius.circular(14)),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, color: Colors.grey)),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'food':
      case 'food & drink':
        return Colors.teal;
      case 'transport':
        return Colors.green;
      case 'bills':
        return Colors.orange;
      case 'shopping':
        return Colors.purple;
      case 'health':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }
}

// helper for mapIndexed
extension _MapIndex<E> on Iterable<E> {
  Iterable<T> mapIndexed<T>(T Function(int index, E e) f) sync* {
    int i = 0;
    for (final e in this) {
      yield f(i++, e);
    }
  }
}
