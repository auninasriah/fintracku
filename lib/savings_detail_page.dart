import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

const Color primaryBlue = Color(0xFF11355F);
const Color accentBlue = Color(0xFF234A78);
const Color accentGreen = Color.fromARGB(255, 34, 139, 34);
const Color softBg = Color(0xFFF7F9FC);
const Color cardBg = Colors.white;
const Color navy = Color(0xFF0D1B2A);

class SavingsDetailPage extends StatefulWidget {
  final String goalId;
  final String goalName;
  final String category;
  final double targetAmount;
  final double currentAmount;

  const SavingsDetailPage({
    super.key,
    required this.goalId,
    required this.goalName,
    required this.category,
    required this.targetAmount,
    required this.currentAmount,
  });

  @override
  State<SavingsDetailPage> createState() => _SavingsDetailPageState();
}

class _SavingsDetailPageState extends State<SavingsDetailPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  late CollectionReference<Map<String, dynamic>> _contributionsRef;
  late DocumentReference<Map<String, dynamic>> _goalRef;

  @override
  void initState() {
    super.initState();
    _initRefs();
  }

  void _initRefs() {
    final user = _auth.currentUser;
    if (user == null) return;
    _contributionsRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savingsGoals')
        .doc(widget.goalId)
        .collection('contributions');
    _goalRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('savingsGoals')
        .doc(widget.goalId);
  }

  Future<void> _addContribution() async {
    final TextEditingController amountCtrl = TextEditingController();
    final TextEditingController noteCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Contribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Amount (RM)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.money),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(
                labelText: 'Note (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final txt = amountCtrl.text.trim();
              final val = double.tryParse(txt);
              if (val == null || val <= 0) return;

              // Add contribution
              await _contributionsRef.add({
                'amount': val,
                'note': noteCtrl.text.trim(),
                'date': Timestamp.now(),
                'createdAt': FieldValue.serverTimestamp(),
              });

              // Update goal's current amount
              await _goalRef.update({
                'currentAmount': FieldValue.increment(val),
                'updatedAt': FieldValue.serverTimestamp(),
              });

              if (!mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Added RM${val.toStringAsFixed(2)} to ${widget.goalName}')),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: accentGreen),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteContribution(String id, double amount) async {
    await _contributionsRef.doc(id).delete();
    await _goalRef.update({
      'currentAmount': FieldValue.increment(-amount),
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
              colors: [Color(0xFF3C79C1), Color(0xFF2A466F)],
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
        title: Text(
          widget.goalName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: accentGreen,
        onPressed: _addContribution,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _goalRef.snapshots(),
        builder: (context, goalSnapshot) {
          if (!goalSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final goalData = goalSnapshot.data!.data();
          final currentAmount = (goalData?['currentAmount'] as num?)?.toDouble() ?? 0.0;
          final progress = widget.targetAmount > 0 ? (currentAmount / widget.targetAmount).clamp(0.0, 1.0) : 0.0;

          return Column(
            children: [
              // Progress Summary Card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF3B8D99), Color(0xFF4F67B5)],
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
                              'Current Saved',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'RM ${formatter.format(currentAmount)}',
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
                              'Target',
                              style: TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'RM ${formatter.format(widget.targetAmount)}',
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
                          'Progress: ${(progress * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          'RM ${formatter.format(widget.targetAmount - currentAmount)} remaining',
                          style: const TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 12,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              // Contributions History
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Contribution History",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: primaryBlue,
                    ),
                  ),
                ),
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _contributionsRef.orderBy('date', descending: true).snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snapshot.data!.docs;
                    if (docs.isEmpty) {
                      return const Center(
                        child: Text('No contributions yet. Tap + to add!'),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: docs.length,
                      itemBuilder: (context, i) {
                        final d = docs[i].data();
                        final id = docs[i].id;
                        final amount = (d['amount'] as num?)?.toDouble() ?? 0.0;
                        final note = d['note'] as String? ?? 'No note';
                        final ts = d['date'] as Timestamp? ?? Timestamp.now();
                        final dateStr = DateFormat('dd MMM yyyy, HH:mm').format(ts.toDate());

                        return Dismissible(
                          key: Key(id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          confirmDismiss: (direction) async {
                            if (!context.mounted) return false;
                            return await showDialog<bool>(
                              context: context,
                              builder: (BuildContext dialogContext) {
                                return AlertDialog(
                                  title: const Text("Confirm Delete"),
                                  content: const Text("Remove this contribution?"),
                                  actions: <Widget>[
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(false),
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(dialogContext).pop(true),
                                      child: const Text("Delete"),
                                    ),
                                  ],
                                );
                              },
                            ) ?? false;
                          },
                          onDismissed: (_) {
                            _deleteContribution(id, amount);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Contribution removed')),
                            );
                          },
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            elevation: 1,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: accentGreen,
                                child: Icon(Icons.add, color: Colors.white),
                              ),
                              title: Text(
                                '+ RM ${formatter.format(amount)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: accentGreen,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(note, style: const TextStyle(fontSize: 13)),
                                  Text(dateStr, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}