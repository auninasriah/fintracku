// income_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'add_income_page.dart';

// PDF creation
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Colors
const Color primaryBlue = Color(0xFF11355F);
const Color incomeGreen = Color(0xFF4CAF50);

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  late CollectionReference incomes;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;

    // ***** FIXED FIREBASE PATH *****
    incomes = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .collection('income');
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
      case "salary": return Icons.account_balance;
      case "allowance": return Icons.child_care;
      case "bonus": return Icons.military_tech;
      case "part time job": return Icons.work;
      case "freelance": return Icons.laptop_mac;
      default: return Icons.wallet;
    }
  }

  // Chart color
  Color _chartColor(String category) {
    switch (category.toLowerCase()) {
      case 'allowance': return Colors.orange;
      case 'part time job': return Colors.blue;
      case 'bonus': return Colors.deepPurple;
      case 'salary': return Colors.yellow.shade700;
      case 'freelance': return Colors.purple;
      default: return Colors.grey;
    }
  }

  // Convert Flutter Color → PDF Int
  int _pdfColor(Color c) {
    return (c.alpha << 24) | (c.red << 16) | (c.green << 8) | c.blue;
  }

  // Delete income
  Future<void> _delete(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Income"),
        content: const Text("Are you sure you want to delete this entry?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      await incomes.doc(id).delete();
    }
  }

  // Edit income
  void _edit(String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddIncomePage(incomeId: id, existingData: data),
      ),
    );
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

            pw.Text("Summary", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              headers: ["Category", "Amount", "Percentage"],
              data: summaryData,
              headerDecoration: pw.BoxDecoration(
                color: PdfColor.fromInt(_pdfColor(primaryBlue)),
              ),
              headerStyle: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold),
            ),

            pw.SizedBox(height: 25),
            pw.Text("Transactions", style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 10),

            pw.TableHelper.fromTextArray(
              headers: ["Date", "Category", "Amount"],
              data: tableData,
            ),

            pw.Spacer(),
            pw.Text("Generated on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}"),
          ],
        ),
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: "income_report_$selectedMonth.pdf",
    );
  }

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: const Text("Income Tracker", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: primaryBlue),
        actions: [
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
                icon: const Icon(Icons.picture_as_pdf),
                onPressed: () => _generatePdf(docs, total, cat),
              );
            },
          ),
        ],
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryBlue,
        child: const Icon(Icons.add),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddIncomePage()),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (_, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
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

          final topCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _infoBox("Total Income", "RM ${totalIncome.toStringAsFixed(2)}",
                        primaryBlue, primaryBlue.withOpacity(0.7)),
                    _infoBox(
                      "Top Category",
                      topCategory.key,
                      incomeGreen,
                      incomeGreen.withOpacity(0.7),
                      sub: "RM ${topCategory.value.toStringAsFixed(2)}",
                    ),
                  ],
                ),
                const SizedBox(height: 25),

                _monthSelector(),
                const SizedBox(height: 25),

                const Text("Income Distribution",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
                const SizedBox(height: 15),

                _donutChart(categoryTotals, totalIncome),
                const SizedBox(height: 25),

                Text("Transactions ($selectedMonth)",
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
                const SizedBox(height: 10),

                Column(
                  children: docs.map((d) {
                    final id = d.id;
                    final data = d.data() as Map<String, dynamic>;
                    final date = (data['date'] as Timestamp).toDate();
                    final amount = (data['amount'] as num).toDouble();
                    final category = data['category'];

                    return Slidable(
                      key: ValueKey(id),

                      startActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            backgroundColor: primaryBlue,
                            icon: Icons.edit,
                            label: "Edit",
                            onPressed: (_) => _edit(id, data),
                          ),
                        ],
                      ),

                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            backgroundColor: Colors.red,
                            icon: Icons.delete,
                            label: "Delete",
                            onPressed: (_) => _delete(id),
                          ),
                        ],
                      ),

                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _chartColor(category),
                            child: Icon(_iconFor(category), color: Colors.white),
                          ),
                          title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(DateFormat('dd MMM yyyy').format(date)),
                          trailing: Text(
                            "+ RM ${amount.toStringAsFixed(2)}",
                            style: const TextStyle(color: incomeGreen, fontWeight: FontWeight.bold),
                          ),
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
    );
  }

  Widget _infoBox(
    String title,
    String value,
    Color a,
    Color b, {
    String? sub,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [a, b]),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text(value, style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            if (sub != null)
              Text(sub, style: const TextStyle(color: Colors.white)),
          ],
        ),
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
              style: const TextStyle(fontSize: 16, color: Colors.black54)),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIncomePage())),
            icon: const Icon(Icons.add_circle, color: primaryBlue),
            label: const Text("Add Income", style: TextStyle(color: primaryBlue)),
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

  Widget _donutChart(Map<String, double> categories, double total) {
    final sections = categories.entries.map((e) {
      return PieChartSectionData(
        value: e.value,
        color: _chartColor(e.key),
        showTitle: false,
        radius: 55,
      );
    }).toList();

    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 75,
            ),
          ),
          Column(
            children: [
              Text(
                "RM ${total.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: primaryBlue),
              ),
              const Text("Total Income", style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}
