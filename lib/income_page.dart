import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import 'add_income_page.dart'; 

// Consistent Color Definitions
const Color primaryBlue = Color(0xFF11355F);
const Color incomeGreen = Color(0xFF4CAF50); // Green for Income/Total
const Color deepPurple = Color(0xFF7E57C2); 

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

  static String _getMonthName(int month) {
    const months = [
      "JAN", "FEB", "MAR", "APR", "MAY", "JUN",
      "JUL", "AUG", "SEP", "OCT", "NOV", "DEC"
    ];
    return (month >= 1 && month <= 12) ? months[month - 1] : months[0];
  }

  // --- Utility Methods for Chart/UI Consistency ---

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'allowance':
        return const Color(0xFF42A5F5); // Lighter Blue
      case 'part time job':
        return const Color(0xFF66BB6A); // Lighter Green
      case 'bonus':
        return const Color(0xFFAB47BC); // Lighter Purple
      case 'salary':
        return const Color(0xFFFFA726); // Amber/Orange
      case 'freelance':
        return deepPurple; // Deep Purple
      default:
        return Colors.grey.shade400; // Neutral default
    }
  }

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

  // --- PDF Generation Feature (FIXED: Using pw.Table to allow custom styling) ---

  Future<void> _generateMonthlyReport(
      List<QueryDocumentSnapshot> docs, double totalIncome) async {
    final pdf = pw.Document();

    final sortedDocs = docs.toList()
      ..sort((a, b) {
        final dateA = (a['date'] as Timestamp).toDate();
        final dateB = (b['date'] as Timestamp).toDate();
        return dateB.compareTo(dateA);
      });

    final tableHeaders = ['Date', 'Category', 'Note', 'Amount (RM)'];

    // 1. Prepare data rows
    List<List<String>> tableData = [];
    for (var doc in sortedDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final date = (data['date'] as Timestamp).toDate();
      final dateString = DateFormat('dd MMM yy').format(date);
      final category = data['category'] ?? 'N/A';
      final note = data['note'] ?? '';
      final amount = (data['amount'] ?? 0.0).toStringAsFixed(2);
      tableData.add([dateString, category, note, '+ RM $amount']);
    }

    // 2. Add Total Income row (last row)
    tableData.add(
        ['', '', 'TOTAL INCOME:', 'RM ${totalIncome.toStringAsFixed(2)}']);

    // 3. Build rows list with header and data, applying styles explicitly
    List<pw.TableRow> pdfRows = [];

    // Header Row
    pdfRows.add(pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF11355F)),
      children: tableHeaders.map((header) {
        return pw.Container(
          alignment: pw.Alignment.centerLeft,
          padding: const pw.EdgeInsets.all(8),
          child: pw.Text(header,
              style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
        );
      }).toList(),
    ));

    // Data Rows with conditional styling
    final totalRowIndex = tableData.length - 1;
    for (int i = 0; i < tableData.length; i++) {
      final isTotalRow = (i == totalRowIndex);
      final row = tableData[i];

      pdfRows.add(pw.TableRow(
        children: row.map((cellText) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(8),
            child: pw.Text(
              cellText,
              style: isTotalRow
                  ? pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 10,
                      color: PdfColor.fromInt(incomeGreen.value), // Green color
                    )
                  : const pw.TextStyle(fontSize: 10),
            ),
          );
        }).toList(),
      ));
    }


    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Income Report for $selectedMonth',
                style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(primaryBlue.value)),
              ),
              pw.SizedBox(height: 10),
              pw.Divider(color: PdfColor.fromInt(primaryBlue.value)),
              pw.SizedBox(height: 20),

              // Transactions Table using manual pw.Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
                columnWidths: const {
                  0: pw.FlexColumnWidth(2),
                  1: pw.FlexColumnWidth(3),
                  2: pw.FlexColumnWidth(4),
                  3: pw.FlexColumnWidth(3),
                },
                children: pdfRows, // Use the pre-built, styled rows
              ),

              pw.SizedBox(height: 30),
              pw.Text(
                  'Report Generated: ${DateFormat('dd MMM yyyy').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
            ],
          );
        },
      ),
    );

    await Printing.sharePdf(
      bytes: await pdf.save(),
      filename: 'Income_Report_${selectedMonth}_${DateTime.now().year}.pdf',
    );
  }

  // --- Custom Widgets ---

  Widget _structuralInfoCard(String title, String mainValue,
      {String? subTitle, required Color startColor, required Color endColor}) {
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
              mainValue,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            if (subTitle != null && subTitle.isNotEmpty)
              Text(
                subTitle,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                ),
              ),
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
          Text(
            "No Income recorded for $selectedMonth.",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, color: Colors.black54),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            icon: const Icon(Icons.add_circle, color: primaryBlue),
            label: const Text(
              "Add Income Now",
              style: TextStyle(
                  color: primaryBlue, fontWeight: FontWeight.bold),
            ),
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AddIncomePage()));
            },
          ),
        ],
      ),
    );
  }

  Widget _monthSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(12, (index) {
          final month = _getMonthName(index + 1);
          final isSelected = month == selectedMonth;
          return GestureDetector(
            onTap: () => setState(() => selectedMonth = month),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? primaryBlue
                    : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: primaryBlue.withOpacity(0.4),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Text(
                month,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  // --- Build Method ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Income Tracker",
          style: TextStyle(
              color: primaryBlue, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: primaryBlue),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          StreamBuilder<QuerySnapshot>(
            stream: incomes.snapshots(), 
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const SizedBox.shrink(); 
              }
              
              final allDocs = snapshot.data!.docs;
              final docs = allDocs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                if (data['date'] == null) return false;
                final date = (data['date'] as Timestamp).toDate();
                return _getMonthName(date.month) == selectedMonth;
              }).toList();
              
              double totalIncome = docs.fold(0.0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return sum + (data['amount'] ?? 0).toDouble();
              });

              if (docs.isEmpty) {
                return const SizedBox.shrink(); 
              }

              return IconButton(
                icon: const Icon(Icons.picture_as_pdf, color: primaryBlue),
                onPressed: () => _generateMonthlyReport(docs, totalIncome),
                tooltip: 'Export Monthly Report PDF',
              );
            },
          ),
        ],
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

          final allDocs = snapshot.data!.docs;
          final docs = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            if (data['date'] == null) return false;
            final date = (data['date'] as Timestamp).toDate();
            return _getMonthName(date.month) == selectedMonth;
          }).toList();

          double totalIncome = 0;
          String highestCategory = 'N/A';
          double highestAmount = 0;
          Map<String, double> categoryTotals = {};

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final amount = (data['amount'] ?? 0).toDouble();
            final category = data['category'] ?? 'Others';

            totalIncome += amount;
            categoryTotals[category] =
                (categoryTotals[category] ?? 0) + amount;
          }
          
          if (categoryTotals.isNotEmpty) {
             highestCategory = categoryTotals.entries.reduce((a, b) => a.value > b.value ? a : b).key;
             highestAmount = categoryTotals[highestCategory] ?? 0;
          }

          final pieSections = categoryTotals.entries.map((entry) {
            final percentage = totalIncome > 0 ? (entry.value / totalIncome * 100) : 0;

            return PieChartSectionData(
              value: entry.value,
              title: percentage > 5 ? '${percentage.toStringAsFixed(1)}%' : '',
              color: _getCategoryColor(entry.key),
              radius: 60,
              titleStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              badgeWidget: totalIncome > 0
                  ? _PieChartCategoryBadge(
                      color: _getCategoryColor(entry.key),
                      text: entry.key,
                    )
                  : null,
              badgePositionPercentageOffset: 1.1,
            );
          }).toList();

          if (docs.isEmpty && allDocs.isNotEmpty) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _monthSelector(), 
                  const SizedBox(height: 40),
                  _noIncomeView(),
                ],
              ),
            );
          }
          
          if (docs.isEmpty) {
              return _noIncomeView();
          }


          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Structural Summary Cards with Gradient
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
                      subTitle: highestCategory != 'N/A' ? "RM ${highestAmount.toStringAsFixed(2)}" : null,
                      startColor: incomeGreen,
                      endColor: const Color(0xFF66BB6A),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Month Selector
                _monthSelector(),

                // 3. Pie Chart Section
                const SizedBox(height: 32), 
                const Text("Income Distribution",
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Center(
                    child: SizedBox(
                      height: 250, 
                      child: totalIncome > 0
                          ? PieChart(
                              PieChartData(
                                sections: pieSections,
                                centerSpaceRadius: 50, 
                                sectionsSpace: 2,
                                pieTouchData: PieTouchData(enabled: true),
                              ),
                            )
                          : Center(
                              child: Text(
                                "No income data for $selectedMonth.",
                                style: TextStyle(color: Colors.grey.shade600),
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Income List Header
                Text("Transactions for $selectedMonth",
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue)),
                const SizedBox(height: 12),

                // 5. Income List
                Column(
                  children: docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final category = data['category'] ?? 'Others';
                    final amount = (data['amount'] ?? 0).toDouble();
                    final color = _getCategoryColor(category);
                    final icon = _getCategoryIcon(category);
                    final date = (data['date'] as Timestamp?)?.toDate();
                    final docId = doc.id;

                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      elevation: 2,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                            vertical: 8, horizontal: 16),
                        leading: CircleAvatar(
                          backgroundColor: color,
                          child: Icon(icon, color: Colors.white),
                        ),
                        title: Text(
                          category,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black87),
                        ),
                        subtitle: Text(
                          date != null
                              ? DateFormat('dd MMM yyyy').format(date)
                              : "No Date",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  "+ RM ${amount.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    color: incomeGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    // Edit button
                                    GestureDetector(
                                      onTap: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddIncomePage(
                                              incomeId: docId,
                                              existingData: data,
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Icon(Icons.edit,
                                          color: Colors.blue, size: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    // Delete button
                                    GestureDetector(
                                      onTap: () => incomes.doc(docId).delete(),
                                      child: const Icon(Icons.delete,
                                          color: Colors.red, size: 20),
                                    ),
                                  ],
                                ),
                              ],
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
        backgroundColor: primaryBlue,
        onPressed: () {
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddIncomePage()));
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// Custom widget for better pie chart labels
class _PieChartCategoryBadge extends StatelessWidget {
  final Color color;
  final String text;

  const _PieChartCategoryBadge({required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}