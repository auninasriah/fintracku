import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'add_savings_page.dart';
import 'savings_detail_page.dart';

// --- Color Definitions ---
const Color primaryBlue = Color(0xFF11355F);
const Color accentBlue = Color(0xFF234A78);
const Color softGray = Color(0xFFF7F9FC);
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple
const Color cardGradientStart = Color(0xFF3C79C1);
const Color accentGreen = Color.fromARGB(255, 34, 139, 34);
const Color softBg = Color(0xFFF7F9FC);
const Color cardBg = Colors.white;
const Color navy = Color(0xFF0D1B2A);

class SavingsPage extends StatefulWidget {
  const SavingsPage({super.key});

  @override
  State<SavingsPage> createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late CollectionReference<Map<String, dynamic>> _savingsGoalsRef;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _initRefs();
  }

  Future<void> _initRefs() async {
    final user = _auth.currentUser;
    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in to view savings')),
        );
      });
      return;
    }
    _savingsGoalsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savingsGoals');
    setState(() {
      _initialized = true;
    });
  }

  Stream<double> _totalSavedStream() {
    if (!_initialized) return const Stream.empty();
    return _savingsGoalsRef.snapshots().map((snap) {
      double total = 0;
      for (final doc in snap.docs) {
        final amt = doc.data()['currentAmount'];
        if (amt is int) total += amt.toDouble();
        if (amt is double) total += amt;
      }
      return total;
    });
  }

  Stream<double> _totalTargetStream() {
    if (!_initialized) return const Stream.empty();
    return _savingsGoalsRef.snapshots().map((snap) {
      double total = 0;
      for (final doc in snap.docs) {
        final amt = doc.data()['targetAmount'];
        if (amt is int) total += amt.toDouble();
        if (amt is double) total += amt;
      }
      return total;
    });
  }

  Future<void> _openAddGoalForm({String? existingId, Map<String, dynamic>? existingData}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddSavingsPage(
        existingId: existingId,
        existingData: existingData,
      ),
    );
  }

  Future<void> _deleteGoal(String id) async {
    if (!_initialized) return;
    
    // Delete all contributions first
    final contributionsRef = _savingsGoalsRef.doc(id).collection('contributions');
    final contributions = await contributionsRef.get();
    for (var doc in contributions.docs) {
      await doc.reference.delete();
    }
    
    // Delete the goal
    await _savingsGoalsRef.doc(id).delete();
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Emergency':
        return Icons.health_and_safety;
      case 'Travel':
        return Icons.flight_takeoff;
      case 'House':
        return Icons.home;
      case 'Wedding':
        return Icons.favorite;
      case 'Car':
        return Icons.directions_car;
      case 'Education':
        return Icons.school;
      default:
        return Icons.savings;
    }
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Emergency':
        return Colors.redAccent;
      case 'Travel':
        return Colors.blueAccent;
      case 'House':
        return Colors.green;
      case 'Wedding':
        return Colors.pinkAccent;
      case 'Car':
        return Colors.orange;
      case 'Education':
        return Colors.purple;
      default:
        return primaryBlue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,##0.00');

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
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          "Savings Tracker",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentBlue,
        onPressed: () => _openAddGoalForm(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: !_initialized
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<double>(
              stream: _totalTargetStream(),
              builder: (context, targetSnap) {
                final totalTarget = targetSnap.data ?? 0.0;
                return StreamBuilder<double>(
                  stream: _totalSavedStream(),
                  builder: (context, totalSnap) {
                    final totalSaved = totalSnap.data ?? 0.0;
                    final overallProgress = totalTarget > 0 ? (totalSaved / totalTarget).clamp(0.0, 1.0) : 0.0;

                    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _savingsGoalsRef.orderBy('createdAt', descending: false).snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final goals = snapshot.data!.docs;

                        // If no goals, show empty state
                        if (goals.isEmpty) {
                          return Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0, bottom: 8.0),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [cardGradientStart, cardGradientEnd],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: primaryBlue.withValues(alpha: 0.2),
                                        blurRadius: 18,
                                        offset: const Offset(0, 10),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text(
                                                'Total Saved',
                                                style: TextStyle(color: Colors.white70, fontSize: 13),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'RM ${formatter.format(totalSaved)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text(
                                                'Total Target',
                                                style: TextStyle(color: Colors.white70, fontSize: 13),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                'RM ${formatter.format(totalTarget)}',
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            totalTarget > 0 ? 'Overall Progress' : 'No goals set',
                                            style: const TextStyle(color: Colors.white70, fontSize: 12),
                                          ),
                                          Text(
                                            totalTarget > 0 ? '${(overallProgress * 100).toStringAsFixed(0)}%' : '',
                                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: LinearProgressIndicator(
                                          value: totalTarget > 0 ? overallProgress : 0,
                                          minHeight: 10,
                                          backgroundColor: Colors.white24,
                                          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      ),
                                    ],
                                  ),
                                ).animate().fadeIn().slideY(begin: 0.1),
                              ),
                              Expanded(
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.savings, size: 80, color: accentGreen.withValues(alpha: 0.5)),
                                        const SizedBox(height: 16),
                                        const Text(
                                          "No savings goals yet.\nCreate your first goal!",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 16, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        }

                        // Main content with goals
                        return SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Top Summary Card
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [cardGradientStart, cardGradientEnd],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryBlue.withValues(alpha: 0.2),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              'Total Saved',
                                              style: TextStyle(color: Colors.white70, fontSize: 13),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'RM ${formatter.format(totalSaved)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 26,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment: CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'Total Target',
                                              style: TextStyle(color: Colors.white70, fontSize: 13),
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              'RM ${formatter.format(totalTarget)}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 20,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'Overall Progress',
                                          style: TextStyle(color: Colors.white70, fontSize: 12),
                                        ),
                                        Text(
                                          '${(overallProgress * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: LinearProgressIndicator(
                                        value: overallProgress,
                                        minHeight: 10,
                                        backgroundColor: Colors.white24,
                                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn().slideY(begin: 0.1),

                              const SizedBox(height: 24),

                              // --- Savings Goals ---
                              const Text(
                                "My Savings Goals",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: primaryBlue,
                                ),
                              ),
                              const SizedBox(height: 12),

                              // Display all goals as cards
                              ...goals.map((doc) {
                                final d = doc.data();
                                final id = doc.id;
                                final name = d['name'] ?? 'Unnamed Goal';
                                final category = d['category'] ?? 'Other';
                                final targetAmount = (d['targetAmount'] as num?)?.toDouble() ?? 0.0;
                                final currentAmount = (d['currentAmount'] as num?)?.toDouble() ?? 0.0;
                                final categoryColor = _categoryColor(category);
                                final progress = targetAmount > 0 ? (currentAmount / targetAmount).clamp(0.0, 1.0) : 0.0;

                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SavingsDetailPage(
                                          goalId: id,
                                          goalName: name,
                                          category: category,
                                          targetAmount: targetAmount,
                                          currentAmount: currentAmount,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Dismissible(
                                    key: Key(id),
                                    direction: DismissDirection.horizontal,
                                    background: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color.fromARGB(255, 82, 15, 10),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: const Icon(Icons.delete, color: Colors.white),
                                    ),
                                    secondaryBackground: Container(
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.blue,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      alignment: Alignment.centerRight,
                                      padding: const EdgeInsets.symmetric(horizontal: 20),
                                      child: const Icon(Icons.edit, color: Colors.white),
                                    ),
                                    confirmDismiss: (direction) async {
                                      if (direction == DismissDirection.startToEnd) {
                                        if (!context.mounted) return false;
                                        final result = await showDialog<bool>(
                                          context: context,
                                          builder: (BuildContext dialogContext) {
                                            return AlertDialog(
                                              title: const Text("Confirm Delete"),
                                              content: const Text("Delete this savings goal and all its contributions?"),
                                              actions: <Widget>[
                                                TextButton(
                                                  onPressed: () => Navigator.of(dialogContext).pop(false),
                                                  child: const Text("Cancel"),
                                                ),
                                                TextButton(
                                                  onPressed: () => Navigator.of(dialogContext).pop(true),
                                                  child: const Text("Delete", style: TextStyle(color: Colors.red)),
                                                ),
                                              ],
                                            );
                                          },
                                        );
                                        return result ?? false;
                                      } else if (direction == DismissDirection.endToStart) {
                                        if (!mounted) return false;
                                        await _openAddGoalForm(
                                          existingId: id,
                                          existingData: d,
                                        );
                                        return false;
                                      }
                                      return false;
                                    },
                                    onDismissed: (direction) async {
                                      if (direction == DismissDirection.startToEnd) {
                                        await _deleteGoal(id);
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Goal deleted successfully')),
                                        );
                                      }
                                    },
                                    child: Card(
                                      color: cardBg,
                                      margin: const EdgeInsets.symmetric(vertical: 6),
                                      elevation: 2,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(10),
                                                  decoration: BoxDecoration(
                                                    color: categoryColor.withValues(alpha: 0.15),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(_categoryIcon(category), color: categoryColor, size: 28),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: const TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          fontSize: 16,
                                                          color: navy,
                                                        ),
                                                      ),
                                                      Text(
                                                        category,
                                                        style: TextStyle(
                                                          fontSize: 13,
                                                          color: Colors.grey.shade600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              padding: const EdgeInsets.all(12),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                    children: [
                                                      Text(
                                                        'RM ${formatter.format(currentAmount)} / RM ${formatter.format(targetAmount)}',
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          color: navy,
                                                        ),
                                                      ),
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                        decoration: BoxDecoration(
                                                          color: accentGreen.withValues(alpha: 0.15),
                                                          borderRadius: BorderRadius.circular(12),
                                                        ),
                                                        child: Text(
                                                          '${(progress * 100).toStringAsFixed(0)}%',
                                                          style: const TextStyle(
                                                            fontSize: 12,
                                                            fontWeight: FontWeight.bold,
                                                            color: accentGreen,
                                                          ),
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                  const SizedBox(height: 8),
                                                  ClipRRect(
                                                    borderRadius: BorderRadius.circular(6),
                                                    child: LinearProgressIndicator(
                                                      value: progress,
                                                      minHeight: 10,
                                                      backgroundColor: Colors.grey.shade300,
                                                      valueColor: const AlwaysStoppedAnimation<Color>(accentGreen),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),

                              const SizedBox(height: 80),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}