// --------------------------------------------------------------
//                  UPDATED INCOME PAGE WITH PDF EXPORT
// --------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'add_income_page.dart';
// PDF Dependencies
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// Consistent Color Definitions
const Color primaryBlue = Color(0xFF11355F);
const Color incomeGreen = Color(0xFF4CAF50);
const Color deepPurple = Color(0xFF7E57C2);

class IncomePage extends StatefulWidget {
  const IncomePage({super.key});

  @override
  State<IncomePage> createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  // Firestore Collection Reference
  final CollectionReference incomes = FirebaseFirestore.instance
      .collection('users')
      .doc('local_user')
      .collection('income');

  String selectedMonth = _getMonthName(DateTime.now().month);

  static String _getMonthName(int month) {
    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : months[0];
  }

  // Function to determine the icon for the category
  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'allowance':
        return Icons.child_care;
      case 'part time job':
        return Icons.work;
      case 'bonus':
        return Icons.military_tech;
      case 'salary':
        return Icons.account_balance;
      case 'freelance':
        return Icons.laptop_chromebook;
      default:
        return Icons.wallet;
    }
  }

  // ----------- COLOR PALETTE FOR DONUT CHART ---------------
  Color _chartColor(String category) {
    switch (category.toLowerCase()) {
      case 'allowance':
        return const Color(0xFFFFA726); // Orange
      case 'part time job':
        return const Color(0xFF42A5F5); // Blue
      case 'bonus':
        return const Color(0xFF1E88E5); // Deep Blue
      case 'salary':
        return const Color(0xFFFFEB3B); // Yellow
      case 'freelance':
        return const Color(0xFF5E35B1); // Purple
      default:
        return const Color(0xFFBDBDBD); // Grey
    }
  }

  // --------------------------------------------------------------
  //                        NEW CRUD FUNCTIONS
  // --------------------------------------------------------------

  // Function to handle deleting an income document from Firebase
  Future<void> _deleteIncome(String docId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Confirm Delete"),
        content: const Text("Are you sure you want to delete this income entry?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await incomes.doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Income entry deleted successfully.")),
        );
      }
    }
  }

  // Function to handle navigating to the AddIncomePage for editing
  void _editIncome(String docId, Map<String, dynamic> currentData) {
    // Navigate to AddIncomePage, passing data for editing if AddIncomePage supports it.
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddIncomePage(),
      ),
    );
  }

  // --------------------------------------------------------------
  //                        PDF GENERATION LOGIC
  // --------------------------------------------------------------

  Future<void> _generatePdf(
    List<QueryDocumentSnapshot> docs,
    double totalIncome,
    Map<String, double> categoryTotals,
  ) async {
    final pdf = pw.Document();

      // Prepare data for PDF table (robust parsing for amount/date)
    final List<List<String>> tableData = docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final category = (data['category'] ?? 'Others').toString();

      // parse amount safely
      double amount;
      final rawAmount = data['amount'];
      if (rawAmount is num) {
        amount = rawAmount.toDouble();
      } else {
        amount = double.tryParse(rawAmount?.toString() ?? '0') ?? 0.0;
      }

      // parse date safely
      DateTime date;
      final rawDate = data['date'];
      if (rawDate is Timestamp) {
        date = rawDate.toDate();
      } else {
        date = DateTime.tryParse(rawDate?.toString() ?? '') ?? DateTime.now();
      }

      return [
        DateFormat('dd MMM yyyy').format(date),
        category,
        "RM ${amount.toStringAsFixed(2)}",
      ];
    }).toList();
    
    // Prepare Summary Data
    final List<List<String>> summaryData = categoryTotals.entries.map((e) {
      return [
        e.key,
        "RM ${e.value.toStringAsFixed(2)}",
        "${((e.value / totalIncome) * 100).toStringAsFixed(1)}%",
      ];
    }).toList();

    // Add Total Row to Summary
    summaryData.add([
      "TOTAL",
      "RM ${totalIncome.toStringAsFixed(2)}",
      "100.0%",
    ]);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Income Report for $selectedMonth',
                  style: pw.TextStyle(
                      fontSize: 24,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromInt(primaryBlue.value))),
              pw.SizedBox(height: 20),

              // Summary Table
              pw.Text('Summary by Category',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Category', 'Amount', 'Percentage'],
                data: summaryData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromInt(primaryBlue.value)),
                cellAlignment: pw.Alignment.centerRight,
                cellAlignments: {0: pw.Alignment.centerLeft},
                border: pw.TableBorder.all(),
              ),

              pw.SizedBox(height: 30),

              // Transactions Table
              pw.Text('Transaction Details',
                  style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 10),
              pw.Table.fromTextArray(
                headers: ['Date', 'Category', 'Amount'],
                data: tableData,
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                border: pw.TableBorder.all(),
                cellAlignment: pw.Alignment.centerRight,
                cellAlignments: {0: pw.Alignment.centerLeft, 1: pw.Alignment.centerLeft},
              ),

              pw.Spacer(),
              pw.Align(
                alignment: pw.Alignment.bottomRight,
                child: pw.Text("Report generated on ${DateFormat('yyyy-MM-dd').format(DateTime.now())}"),
              )
            ],
          );
        },
      ),
    );

    // Display the PDF preview
    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'income_report_${selectedMonth.toLowerCase()}.pdf',
    );
  }

  // --------------------------------------------------------------
  //                          UI SECTIONS
  // --------------------------------------------------------------

  Widget _structuralInfoCard(
    String title,
    String mainValue, {
    String? subTitle,
    required Color startColor,
    required Color endColor,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8.0),
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
              color: startColor.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, color: Colors.white70)),
            const SizedBox(height: 6),
            Text(mainValue,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            if (subTitle != null) Text(subTitle, style: const TextStyle(color: Colors.white)),
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
          const SizedBox(height: 16),
          Text("No Income recorded for $selectedMonth.",
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, color: Colors.black54)),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add_circle, color: primaryBlue),
            label: const Text("Add Income Now", style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIncomePage())),
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
          final month = _getMonthName(i + 1);
          final isSelected = month == selectedMonth;

          return GestureDetector(
            onTap: () => setState(() => selectedMonth = month),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? primaryBlue : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(month,
                  style: TextStyle(color: isSelected ? Colors.white : Colors.black87, fontWeight: FontWeight.bold)),
            ),
          );
        }),
      ),
    );
  }

  // --------------------------------------------------------------
  //                     DONUT CHART WITH LABELS
  // --------------------------------------------------------------

  Widget buildDonutChart(
    Map<String, double> categories,
    double totalIncome,
  ) {
    final List<PieChartSectionData> sections = categories.entries.map((e) {
      return PieChartSectionData(
        value: e.value,
        color: _chartColor(e.key),
        radius: 55,
        showTitle: false,
      );
    }).toList();

    return SizedBox(
      height: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(
            PieChartData(
              centerSpaceRadius: 70,
              sectionsSpace: 3,
              sections: sections,
            ),
          ),

          // Center income text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "RM ${totalIncome.toStringAsFixed(2)}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue),
              ),
              const SizedBox(height: 4),
              const Text(
                "Total Income",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------
  //                          BUILD
  // --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: incomes.orderBy('date', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;

          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['date'] == null) return false;

            final date = (data['date'] as Timestamp).toDate();
            return _getMonthName(date.month) == selectedMonth;
          }).toList();

          double totalIncome = 0;
          Map<String, double> categoryTotals = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0).toDouble();
            final category = data['category'] ?? 'Others';

            totalIncome += amount;
            categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          }

          final highestCategory = totalIncome > 0
              ? categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key
              : 'N/A';
          final highestAmount = totalIncome > 0 ? categoryTotals[highestCategory]! : 0.0;

          return Scaffold(
            appBar: AppBar(
              title: const Text("Income Tracker",
                  style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(icon: const Icon(Icons.arrow_back, color: primaryBlue), onPressed: () => Navigator.pop(context)),
              // NEW: PDF Download Button
              actions: [
                if (totalIncome > 0)
                  IconButton(
                    icon: const Icon(Icons.picture_as_pdf, color: primaryBlue),
                    onPressed: () => _generatePdf(docs, totalIncome, categoryTotals),
                  ),
              ],
            ),

            floatingActionButton: FloatingActionButton(
              backgroundColor: primaryBlue,
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddIncomePage())),
              child: const Icon(Icons.add, color: Colors.white),
            ),

            body: docs.isEmpty
                ? _noIncomeView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary Cards
                        Row(
                          children: [
                            _structuralInfoCard(
                              "Total Income",
                              "RM ${totalIncome.toStringAsFixed(2)}",
                              startColor: primaryBlue,
                              endColor: const Color(0xFF345A8B),
                            ),
                            _structuralInfoCard(
                              "Top Category",
                              highestCategory,
                              subTitle: "RM ${highestAmount.toStringAsFixed(2)}",
                              startColor: incomeGreen,
                              endColor: const Color(0xFF66BB6A),
                            ),
                          ],
                        ),

                        const SizedBox(height: 30),

                        _monthSelector(),

                        const SizedBox(height: 30),

                        const Text("Income Distribution",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
                        const SizedBox(height: 12),

                        buildDonutChart(categoryTotals, totalIncome),

                        const SizedBox(height: 30),

                        Text("Transactions for $selectedMonth",
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: primaryBlue)),
                        const SizedBox(height: 12),

                        Column(
                          children: docs.map((doc) {
                            final docId = doc.id;
                            final data = doc.data() as Map<String, dynamic>;
                            final category = data['category'] ?? 'Others';
                            final amount = (data['amount'] ?? 0).toDouble();
                            final icon = _getCategoryIcon(category);
                            final date = (data['date'] as Timestamp).toDate();

                            return Card(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              margin: const EdgeInsets.only(bottom: 10),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _chartColor(category),
                                  child: Icon(icon, color: Colors.white),
                                ),
                                title: Text(category, style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Text(DateFormat('dd MMM yyyy').format(date), style: const TextStyle(color: Colors.grey)),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Amount Text
                                    Padding(
                                      padding: const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        "+ RM ${amount.toStringAsFixed(2)}",
                                        style: const TextStyle(color: incomeGreen, fontWeight: FontWeight.bold, fontSize: 14),
                                      ),
                                    ),

                                    // Edit Button
                                    SizedBox(
                                      width: 30,
                                      child: IconButton(
                                        icon: const Icon(Icons.edit, size: 20, color: primaryBlue),
                                        onPressed: () => _editIncome(docId, data),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                    const SizedBox(width: 4),

                                    // Delete Button
                                    SizedBox(
                                      width: 30,
                                      child: IconButton(
                                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                                        onPressed: () => _deleteIncome(docId),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
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
                  ),
          );
        },
      ),
    );
  }
}