import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/gamification_service.dart';
import 'expenses_page.dart';
import 'home_page.dart';

const Color primaryBlue = Color(0xFF11355F);
const Color accentBlue = Color(0xFF234A78);
const Color cardGradientEnd = Color(0xFF3F2A61); // Vibrant Purple
const Color cardGradientStart = Color(0xFF3C79C1);
const Color softGray = Color(0xFFF2F2F4);


class SmartSpendMainPage extends StatefulWidget {
  const SmartSpendMainPage({super.key});

  @override
  State<SmartSpendMainPage> createState() => _SmartSpendMainPageState();
}

class _SmartSpendMainPageState extends State<SmartSpendMainPage> {
  late GamificationService _gamificationService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _gamificationService = GamificationService();
    
    // ✅ Initialize FIRST, then check overspending
    _initializeAndCheck();
  }

  // ✅ NEW: Initialize gamification then check overspending
  Future<void> _initializeAndCheck() async {
    try {
      // Step 1: Initialize gamification
      final gamificationData = await _gamificationService.getOrInitializeUserGamification();
      final isNewUser = gamificationData['isNewInit'] as bool? ?? false;
      
      debugPrint('🎮 Gamification initialized. New user: $isNewUser');
      
      // Step 2: Check daily streak and award points
      final streakData = await _gamificationService.checkAndUpdateStreak();
      final pointsEarned = streakData['pointsEarned'] as double;
      final bonusEarned = streakData['bonusEarned'] as double;
      final currentStreak = streakData['currentStreak'] as int;
      
      if (pointsEarned > 0 && mounted) {
        _showStreakReward(pointsEarned, bonusEarned, currentStreak);
      }
      
      // Step 3: Wait then check overspending
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (isNewUser && mounted) {
        await _checkAndNotifyOverspending();
      }
    } catch (e) {
      debugPrint('❌ Error in initialization: $e');
    }
  }

  // ✅ NEW: Show streak reward dialog
  void _showStreakReward(double points, double bonus, int streak) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '🔥 Daily Streak!',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.orange,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${streak} Day${streak > 1 ? 's' : ''}',
              style: GoogleFonts.inter(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: cardGradientStart,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '+${points.toInt()} SP earned!',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
            if (bonus > 0) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '🎉 BONUS: +${bonus.toInt()} SP',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('AWESOME!'),
          ),
        ],
      ),
    );
  }

  // ✅ COMPLETE FIX: Force check and deduct immediately if overspending
  Future<void> _checkAndNotifyOverspending() async {
    try {
      final budgetLimit = await _getMonthlyBudgetLimit();
      if (budgetLimit == null) {
        debugPrint('⚠️ No budget limit set');
        return;
      }
      
      final currentExpenses = await _getTotalMonthlyExpenses();
      
      debugPrint('📊 Budget Check:');
      debugPrint('   - Budget Limit: RM$budgetLimit');
      debugPrint('   - Total Expenses: RM$currentExpenses');
      
      if (currentExpenses <= budgetLimit) {
        debugPrint('✅ Within budget - no action needed');
        return;
      }
      
      // Calculate overspend amount
      final overspentAmount = currentExpenses - budgetLimit;
      debugPrint('🚨 OVERSPENDING: RM$overspentAmount');
      
      // Get overspend data
      final overspendData = await _gamificationService.checkOverspending(
        totalMonthlyExpense: currentExpenses,
        monthlyBudgetLimit: budgetLimit,
      );

      if (overspendData == null) {
        debugPrint('⚠️ No overspend data returned');
        return;
      }

      if (!mounted) return;
      
      // Get current points
      final currentPoints = await _gamificationService.getCurrentMonthPoints();
      final deductionAmount = overspendData['deductionAmount'] as double;
      
      debugPrint('💰 Points Status:');
      debugPrint('   - Current Points: $currentPoints SP');
      debugPrint('   - Deduction Amount: $deductionAmount SP');
      
      // Always deduct points when overspending
      await _gamificationService.deductPoints(
        amount: deductionAmount,
        reason: 'overspent_rm${overspentAmount.toStringAsFixed(2)}',
      );
      
      debugPrint('✅ Points deducted successfully');

      // Add current points for dialog display
      overspendData['currentPoints'] = currentPoints;

      if (mounted) {
        // Small delay to ensure state updates
        await Future.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          _showOverspendingAlert(overspendData);
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _checkAndNotifyOverspending: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  // ✅ Overspending alert dialog
  void _showOverspendingAlert(Map<String, dynamic> overspendData) {
    final overspentAmount = (overspendData['overspentAmount'] as num).toDouble();
    final deductionAmount = (overspendData['deductionAmount'] as num).toDouble();
    final currentPoints = (overspendData['currentPoints'] as num).toDouble();
    final newPoints = currentPoints - deductionAmount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          '🚨 OVERSPENDING ALERT!',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.red,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You exceeded your budget!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Overspent: RM ${overspentAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Budget Limit: RM ${(overspendData['budgetLimit'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Total Expenses: RM ${(overspendData['totalExpense'] as num).toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎮 Points Deducted',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.deepOrange,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Before: ${currentPoints.toStringAsFixed(0)} SP',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Icon(Icons.arrow_forward, size: 16),
                      Text(
                        'After: ${newPoints.toStringAsFixed(0)} SP',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '-${deductionAmount.toStringAsFixed(0)} SP penalty',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '💡 Tip: Try reducing expenses to get back on track!',
              style: TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<String> _getUserName() async {
    final user = _auth.currentUser;
    if (user == null) return 'User';

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      return (doc.data()?['name'] as String?) ?? user.email?.split('@')[0] ?? 'User';
    } catch (e) {
      debugPrint('❌ Error fetching user name: $e');
      return user.email?.split('@')[0] ?? 'User';
    }
  }

  Future<double?> _getMonthlyBudgetLimit() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('budget')
          .get();

      return (doc.data()?['monthlyLimit'] as num?)?.toDouble();
    } catch (e) {
      debugPrint('❌ Error fetching budget limit: $e');
      return null;
    }
  }

  // ✅ Calculate total monthly expenses
  Future<double> _getTotalMonthlyExpenses() async {
    final user = _auth.currentUser;
    if (user == null) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .get();

      double total = 0.0;
      for (var doc in snapshot.docs) {
        final amount = doc['amount'];
        if (amount is int) {
          total += amount.toDouble();
        } else if (amount is double) {
          total += amount;
        }
      }
      return total;
    } catch (e) {
      debugPrint('❌ Error calculating expenses: $e');
      return 0.0;
    }
  }

  Stream<double> _getTotalExpensesStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('expenses')
        .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
        .where('timestamp', isLessThanOrEqualTo: endOfMonth)
        .snapshots()
        .map((snapshot) {
          double total = 0.0;
          for (var doc in snapshot.docs) {
            final amount = doc['amount'];
            if (amount is int) {
              total += amount.toDouble();
            } else if (amount is double) {
              total += amount;
            }
          }
          return total;
        });
  }

  Stream<double> _getCurrentMonthPointsStream() {
    return _gamificationService.getCurrentMonthPointsStream();
  }

  Widget _buildSmartScoreCircle(double points) {
    final pointsInt = points.toInt();

    Color statusColor;
    String statusEmoji;
    if (pointsInt >= 80) {
      statusColor = Colors.greenAccent;
      statusEmoji = '✨';
    } else if (pointsInt >= 50) {
      statusColor = Colors.yellowAccent;
      statusEmoji = '⚡';
    } else {
      statusColor = Colors.redAccent;
      statusEmoji = '⚠️';
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  cardGradientStart,
                  cardGradientEnd,
                ],
              ),
              border: Border.all(
                color: Colors.white,
                width: 3,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  points.toStringAsFixed(0),
                  style: GoogleFonts.inter(
                    fontSize: 50,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black.withValues(alpha: 0.3),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SP',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: 5,
            right: 5,
            child: Text(
              statusEmoji,
              style: const TextStyle(fontSize: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBudgetQuestCard({
    required double? budgetLimit,
    required double expense,
  }) {
    if (budgetLimit == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: softGray,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: primaryBlue, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Set your monthly budget to start the quest!',
                style: GoogleFonts.inter(
                  color: primaryBlue,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    double progress = budgetLimit > 0 ? expense / budgetLimit : 0.0;
    Color barColor = progress > 0.85 ? const Color(0xFFD32F2F) : cardGradientStart;

    String statusText;
    if (progress > 1.0) {
      statusText = 'OVERSPEND DETECTED! 🚨';
    } else if (progress > 0.85) {
      statusText = 'APPROACHING LIMIT ⚠️';
    } else {
      statusText = 'ON TRACK ✅';
    }

    double displayProgress = progress.clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Budget Quest',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: primaryBlue,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: progress > 0.85 ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                statusText,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: progress > 0.85 ? Colors.red : Colors.green,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: displayProgress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RM ${expense.toStringAsFixed(2)} / RM ${budgetLimit.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                color: primaryBlue,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              progress < 1.0 
                ? 'Remaining: RM ${(budgetLimit - expense).toStringAsFixed(2)}'
                : 'Overspent: RM ${(expense - budgetLimit).toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                color: progress < 1.0 ? Colors.green : Colors.red,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, size: 16),
          label: Text(
            label,
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: accentBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
    );
  }

  void _showLimitSetupDialog() {
    final TextEditingController limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            '🎯 Set Monthly Budget',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              color: primaryBlue,
            ),
          ),
          content: TextField(
            controller: limitController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              hintText: '500.00',
              labelText: 'Monthly Limit (RM)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.money),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'CANCEL',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final limitText = limitController.text.trim();
                if (limitText.isEmpty) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount')),
                    );
                  }
                  return;
                }

                final limit = double.tryParse(limitText);
                if (limit == null || limit <= 0) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Please enter a valid amount')),
                    );
                  }
                  return;
                }

                final user = _auth.currentUser;
                if (user == null) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('User not authenticated')),
                    );
                  }
                  return;
                }

                try {
                  await _firestore
                      .collection('users')
                      .doc(user.uid)
                      .collection('settings')
                      .doc('budget')
                      .set({
                    'monthlyLimit': limit,
                    'updatedAt': FieldValue.serverTimestamp(),
                  }, SetOptions(merge: true));

                  if (!mounted) return;
                  Navigator.of(dialogContext).pop();

                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('✅ Budget set to RM ${limit.toStringAsFixed(2)}!'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 2),
                    ),
                  );

                  if (!mounted) return;
                  setState(() {});
                  
                  // ✅ Check overspending after setting budget
                  _checkAndNotifyOverspending();
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                  debugPrint('❌ Error setting budget: $e');
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cardGradientStart,
              ),
              child: Text(
                'SAVE',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: softGray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const MainShell()),
            );
          },
        ),
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
          'Smart Spend',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [cardGradientStart, cardGradientEnd],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: primaryBlue.withValues(alpha: 0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        FutureBuilder<String>(
                          future: _getUserName(),
                          builder: (context, snapshot) {
                            final userName = snapshot.data ?? 'User';
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Welcome',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: primaryBlue.withValues(alpha: 0.6),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  userName,
                                  style: GoogleFonts.inter(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    color: primaryBlue,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        StreamBuilder<double>(
                          stream: _getCurrentMonthPointsStream(),
                          builder: (context, snapshot) {
                            final points = snapshot.data ?? 100.0;
                            return _buildSmartScoreCircle(points);
                          },
                        ),

                        const SizedBox(height: 20),

                        // ✅ NEW: Daily Streak Display
                        FutureBuilder<int>(
                          future: _gamificationService.getCurrentStreak(),
                          builder: (context, snapshot) {
                            final streak = snapshot.data ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [Colors.orange.shade400, Colors.deepOrange.shade500],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥', style: TextStyle(fontSize: 24)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$streak Day Streak',
                                    style: GoogleFonts.inter(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 28),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _showLimitSetupDialog,
                            icon: const Icon(Icons.edit, size: 18),
                            label: Text(
                              'Set Budget',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cardGradientStart,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        FutureBuilder<double?>(
                          future: _getMonthlyBudgetLimit(),
                          builder: (context, budgetSnapshot) {
                            final budgetLimit = budgetSnapshot.data;

                            return StreamBuilder<double>(
                              stream: _getTotalExpensesStream(),
                              builder: (context, expenseSnapshot) {
                                final expense = expenseSnapshot.data ?? 0.0;

                                return _buildBudgetQuestCard(
                                  budgetLimit: budgetLimit,
                                  expense: expense,
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        Row(
                          children: [
                            _buildActionButton(
                              label: 'Expenses',
                              icon: Icons.receipt,
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ExpensesPage()),
                                );
                              },
                            ),
                            _buildActionButton(
                              label: 'History',
                              icon: Icons.history,
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('History feature coming soon!')),
                                );
                              },
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: softGray,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Text(
                                '⭐',
                                style: TextStyle(fontSize: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Daily Challenge',
                                      style: GoogleFonts.inter(
                                        color: primaryBlue,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Log in daily to maintain your streak!',
                                      style: GoogleFonts.inter(
                                        color: primaryBlue.withValues(alpha: 0.6),
                                        fontSize: 10,
                                        height: 1.4,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}