import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/gamification_service.dart';
import 'expenses_page.dart';
import 'income_page.dart';
import 'home_page.dart';
import 'gamified_smartspend.dart';

const Color primaryBlue = Color(0xFF3C79C1); // Vibrant Light Blue
const Color accentBlue = Color(0xFF2A466F); // Deep Blue
const Color lightAccent = Color(0xFF3F2A61); // Vibrant Purple
const Color cardGradientStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple
const Color softGray = Color(0xFFF2F2F4);

// RPG Theme Colors
const Color rpgNavyDark = Color(0xFF0F1419); // Deep Navy
const Color rpgPurpleDark = Color(0xFF2D1B4E); // Deep Purple
const Color rpgGlassLight = Color(0xFFFFFFFF); // Glassmorphism base
const Color rpgHealthGreen = Color(0xFF10B981); // Emerald Green
const Color rpgHealthYellow = Color(0xFFFCD34D); // Golden Yellow
const Color rpgHealthRed = Color(0xFFEF4444); // Crimson Red
const Color rpgFlameOrange = Color(0xFFF97316); // Flame Orange


class SmartSpendMainPage extends StatefulWidget {
  const SmartSpendMainPage({super.key});

  @override
  State<SmartSpendMainPage> createState() => _SmartSpendMainPageState();
}

class _SmartSpendMainPageState extends State<SmartSpendMainPage> {
  late GamificationService _gamificationService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // ✅ NEW: Track last overspending alert to prevent duplicates
  DateTime? _lastOverspendingAlertTime;
  static const Duration _alertDebounce = Duration(seconds: 5);
  
  // ✅ NEW: Force stream rebuild when points change
  late Stream<double> _pointsStream;

  @override
  void initState() {
    super.initState();
    _gamificationService = GamificationService();
    
    // ✅ Initialize stream for real-time point updates
    _pointsStream = _getCurrentMonthPointsStream();
    
    // ✅ Initialize FIRST, then check daily income for streak
    _initializeAndCheck();
  }

  // ✅ NEW: Initialize gamification then check daily income
  Future<void> _initializeAndCheck() async {
    try {
      // Step 1: Initialize gamification
      final gamificationData = await _gamificationService.getOrInitializeUserGamification();
      debugPrint('🎮 Gamification initialized.');
      
      // Step 2: Check daily income for streak (one-time on app start)
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        await _checkDailyIncomeStreak();
      }
    } catch (e) {
      debugPrint('❌ Error in initialization: $e');
    }
  }

  // ✅ NEW: Check daily income entry for streak
  Future<void> _checkDailyIncomeStreak() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final startOfDay = today;
      final endOfDay = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // Check if user has added income TODAY
      final incomeSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('income')
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(1)
          .get();

      if (incomeSnapshot.docs.isEmpty) {
        debugPrint('⚠️ No income entry today - streak will not be maintained');
        return;
      }

      // Income entry exists for today - update streak
      debugPrint('✅ Income entry found for today - updating streak');
      final streakData = await _gamificationService.checkAndUpdateStreak();
      final pointsEarned = streakData['pointsEarned'] as double;
      final bonusEarned = streakData['bonusEarned'] as double;
      final currentStreak = streakData['currentStreak'] as int;
      
      if (pointsEarned > 0 && mounted) {
        _showStreakReward(pointsEarned, bonusEarned, currentStreak);
      }
    } catch (e) {
      debugPrint('❌ Error checking income streak: $e');
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

  // ✅ COMPLETE FIX: Check overspending EVERY time page loads or data changes
  // This ensures points are deducted immediately when:
  // 1) User opens Smart Spend page
  // 2) User adds/edits an expense (page refreshes)
  // 3) Budget limit is changed
  // 4) If back within budget, points are RESTORED
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
      
      // ✅ NEW: Check if WITHIN budget - restore points
      if (currentExpenses <= budgetLimit) {
        debugPrint('✅ Within budget - checking if points need restoration');
        await _restorePointsIfNeeded(budgetLimit, currentExpenses);
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
        // ✅ Debounce: Only show alert if not shown recently
        final now = DateTime.now();
        if (_lastOverspendingAlertTime == null || 
            now.difference(_lastOverspendingAlertTime!) > _alertDebounce) {
          _lastOverspendingAlertTime = now;
          await Future.delayed(const Duration(milliseconds: 300));
          if (mounted) {
            _showOverspendingAlert(overspendData);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error in _checkAndNotifyOverspending: $e');
      debugPrint('   Stack trace: ${StackTrace.current}');
    }
  }

  // ✅ NEW: Track if already checked to prevent duplicate restoration
  bool _isCheckingBudget = false;

  // ✅ NEW: Restore points when user is back within budget
  Future<void> _restorePointsIfNeeded(double budgetLimit, double currentExpenses) async {
    try {
      // ✅ Prevent duplicate checks from stream
      if (_isCheckingBudget) {
        debugPrint('⏳ Already checking budget, skipping duplicate check');
        return;
      }

      _isCheckingBudget = true;

      final currentPoints = await _gamificationService.getCurrentMonthPoints();
      
      debugPrint('🔍 Restore Check: Current Points = $currentPoints SP');
      
      // If points are already at 100, no need to restore
      if (currentPoints >= 100) {
        debugPrint('✅ Points already at max (100 SP), no restoration needed');
        _isCheckingBudget = false;
        return;
      }
      
      // Calculate savings amount
      final savingsAmount = budgetLimit - currentExpenses;
      
      debugPrint('💚 User is within budget!');
      debugPrint('   - Current Points: $currentPoints SP');
      debugPrint('   - Savings: RM${savingsAmount.toStringAsFixed(2)}');
      
      // Restore points to 100 since user is now within budget
      final restoreAmount = 100.0 - currentPoints;
      
      if (restoreAmount > 0) {
        debugPrint('🔄 Attempting to restore $restoreAmount SP...');
        
        await _gamificationService.addPoints(
          amount: restoreAmount,
          reason: 'restored_back_within_budget_savings_rm${savingsAmount.toStringAsFixed(2)}',
        );
        
        debugPrint('✅ Points restored: $currentPoints -> 100 SP (+$restoreAmount)');
        
        if (mounted) {
          // Show restoration alert
          _showPointsRestoredAlert(restoreAmount, currentExpenses, budgetLimit);
        }
      }
      
      _isCheckingBudget = false;
    } catch (e) {
      debugPrint('❌ Error restoring points: $e');
      _isCheckingBudget = false;
    }
  }

  // ✅ NEW: Show points restored dialog
  void _showPointsRestoredAlert(double restoreAmount, double currentExpenses, double budgetLimit) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          '🎉 Points Restored!',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.green,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'You\'re back within budget!',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Expenses: RM ${currentExpenses.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Budget: RM ${budgetLimit.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '🎮 Points Restored',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Previously: ${(100 - restoreAmount).toStringAsFixed(0)} SP',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const Icon(Icons.arrow_forward, size: 16),
                      Text(
                        'Now: 100 SP',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '+${restoreAmount.toStringAsFixed(0)} SP restored',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '💡 Keep maintaining your budget!',
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
            child: const Text('GREAT!'),
          ),
        ],
      ),
    );
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
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
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
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
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
        })
        .map((total) {
          // ✅ AUTO-TRIGGER: Check overspending whenever expenses change
          _checkAndNotifyOverspending();
          return total;
        });
  }

  Stream<double> _getCurrentMonthPointsStream() {
    final stream = _gamificationService.getCurrentMonthPointsStream();
    
    // ✅ Add debugging to see stream emissions
    return stream.map((points) {
      debugPrint('📡 Stream emission detected: $points SP');
      return points;
    });
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

  // ✅ NEW: Quest Map Design with flags and percentage pill
  Widget _buildBudgetQuestMap({
    required double? budgetLimit,
    required double expense,
  }) {
    if (budgetLimit == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Set your monthly budget to start the quest!',
                style: GoogleFonts.inter(
                  color: Colors.white,
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
    Color barColor = progress > 0.85 ? rpgHealthRed : primaryBlue;
    Color percentageColor = progress > 0.85 ? rpgHealthRed : rpgHealthGreen;

    String statusText;
    if (progress > 1.0) {
      statusText = 'OVERSPEND DETECTED!';
    } else if (progress > 0.85) {
      statusText = 'APPROACHING LIMIT';
    } else {
      statusText = 'ON TRACK';
    }

    double displayProgress = progress.clamp(0.0, 1.0);
    int percentageValue = (displayProgress * 100).toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Quest: Budget Mission',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: progress > 0.85 ? rpgHealthRed.withValues(alpha: 0.2) : Colors.green.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: progress > 0.85 ? rpgHealthRed.withValues(alpha: 0.5) : Colors.green.withValues(alpha: 0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    progress > 0.85 ? '⚠️' : '✅',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    statusText,
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: progress > 0.85 ? rpgHealthRed : Colors.green,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Quest Map Progress Bar with Flags
        Stack(
          children: [
            // Progress bar background
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: displayProgress,
                minHeight: 12,
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(barColor),
              ),
            ),
            // Flag markers at 25%, 50%, 75%, 100%
            Positioned.fill(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  return Stack(
                    children: [
                      _buildFlagMarker(width, 0.25),
                      _buildFlagMarker(width, 0.50),
                      _buildFlagMarker(width, 0.75),
                      _buildFlagMarker(width, 1.0),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Percentage pill
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: percentageColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: percentageColor.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Text(
            '$percentageValue%',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: percentageColor,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'RM ${expense.toStringAsFixed(2)} / RM ${budgetLimit.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              progress < 1.0 
                ? 'Remaining: RM ${(budgetLimit - expense).toStringAsFixed(2)}'
                : 'Overspent: RM ${(expense - budgetLimit).toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                color: progress < 1.0 ? rpgHealthGreen : rpgHealthRed,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ✅ NEW: Flag marker for quest map
  Widget _buildFlagMarker(double width, double position) {
    return Positioned(
      left: width * position - 6,
      top: -8,
      child: Text(
        '🚩',
        style: TextStyle(
          fontSize: 14,
          shadows: [
            Shadow(
              blurRadius: 4,
              color: Colors.black.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Category breakdown showing budget distribution
  Widget _buildCategoryBreakdown(double? budgetLimit, double totalExpense) {
    if (budgetLimit == null || totalExpense == 0) {
      return const SizedBox.shrink();
    }

    // Category icons and labels
    final categories = [
      {'icon': '🍔', 'label': 'Food'},
      {'icon': '🚗', 'label': 'Transport'},
      {'icon': '🎬', 'label': 'Entertainment'},
      {'icon': '💰', 'label': 'Other'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Budget Breakdown',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: categories.map((category) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.15),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(category['icon'] as String, style: const TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    category['label'] as String,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
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

  // ✅ NEW: Heal Button (🦉⚔️) - Opens Budget Slasher Game
  Widget _buildHealButton() {
    return GestureDetector(
      onTap: _playBudgetSlasherGame,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              cardGradientStart.withValues(alpha: 0.8),
              cardGradientEnd.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: cardGradientStart.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '🦉⚔️',
          style: GoogleFonts.inter(fontSize: 20),
        ),
      ),
    );
  }

  // ✅ NEW: Launch Budget Slasher Game
  void _playBudgetSlasherGame() async {
    try {
      final result = await Navigator.push<int>(
        context,
        MaterialPageRoute(
          builder: (context) => GameWidget(
            onGameOver: _handleGameOver,
          ),
        ),
      );

      // If game returned HP earned, show success dialog
      if (result != null && result > 0) {
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => SuccessDialog(hpEarned: result),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error launching game: $e');
    }
  }

  // ✅ NEW: Handle game over - Update points based on current value
  void _handleGameOver(int hpEarned) async {
    try {
      if (!mounted) return;

      // Get current points from database
      final currentPoints = await _gamificationService.getCurrentMonthPoints();
      
      debugPrint('🎮 Game Over Handler:');
      debugPrint('   - HP Earned: $hpEarned');
      debugPrint('   - Current Points: $currentPoints');

      // Scenario: If currentPoints < 100, add earned HP (can reach 100)
      if (currentPoints < 100) {
        final newPoints = (currentPoints + hpEarned).clamp(0, 100);
        final pointsToAdd = newPoints - currentPoints;

        await _gamificationService.addPoints(
          amount: pointsToAdd,
          reason: 'earned_from_budget_slasher_game_hp_$hpEarned',
        );

        debugPrint('✅ Points Added: $currentPoints -> $newPoints SP (+$pointsToAdd)');
      }
      // Scenario: If currentPoints == 100, add to training XP instead
      else if (currentPoints == 100) {
        // Add to trainingXP or fintrackuCoins field
        final user = _auth.currentUser;
        if (user != null) {
          await _firestore
              .collection('users')
              .doc(user.uid)
              .collection('gamification')
              .doc('stats')
              .update({
                'trainingXP': FieldValue.increment(hpEarned * 10), // 10 XP per HP
              })
              .onError((e, st) {
                // If field doesn't exist, create it
                return _firestore
                    .collection('users')
                    .doc(user.uid)
                    .collection('gamification')
                    .doc('stats')
                    .set({
                      'trainingXP': hpEarned * 10,
                    }, SetOptions(merge: true));
              });

          debugPrint('✅ Training XP Added: ${hpEarned * 10} XP');
        }
      }

      // Force stream rebuild to show updated points
      if (mounted) {
        setState(() {
          _pointsStream = _getCurrentMonthPointsStream();
        });
      }
    } catch (e) {
      debugPrint('❌ Error in _handleGameOver: $e');
    }
  }

  void _showLimitSetupDialog() {
    final TextEditingController limitController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            'Set Monthly Budget',
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
      backgroundColor: cardGradientStart,
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
          'Smart Spend RPG',
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ✅ HEADER WITH MASCOT (Top Left) + HEAL BUTTON (Right)
                FutureBuilder<String>(
                  future: _getUserName(),
                  builder: (context, snapshot) {
                    final userName = snapshot.data ?? 'User';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 24),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // LEFT SIDE: Avatar + Welcome Text
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // Circular Mascot Avatar
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: rpgGlassLight.withValues(alpha: 0.15),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.sentiment_very_satisfied,
                                  color: Colors.white,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 16),
                              // Welcome Text (Top Left)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Welcome back,',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white.withValues(alpha: 0.6),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    userName,
                                    style: GoogleFonts.inter(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          // RIGHT SIDE: Heal Button (🦉⚔️)
                          _buildHealButton(),
                        ],
                      ),
                    );
                  },
                ),

                // ✅ HEALTH POINTS (HP) RING - RPG Style
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: StreamBuilder<double>(
                    stream: _pointsStream,
                    builder: (context, snapshot) {
                      final points = snapshot.data ?? 100.0;
                      debugPrint('🎯 Points Stream Updated: $points SP');
                      return _buildHealthPointsRing(points);
                    },
                  ),
                ),

                // ✅ 7-DAY STREAK TRACKER
                Padding(
                  padding: const EdgeInsets.only(bottom: 28),
                  child: FutureBuilder<int>(
                    future: _gamificationService.getCurrentStreak(),
                    builder: (context, snapshot) {
                      final streak = snapshot.data ?? 0;
                      return _buildSevenDayStreakTracker(streak);
                    },
                  ),
                ),

                const SizedBox(height: 28),

                // ✅ MOTIVATIONAL CARD: Daily Challenge (Glassmorphism)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const IncomePage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: rpgGlassLight.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Daily Challenge',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Log in daily to maintain your streak!',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.arrow_forward, color: Colors.white.withValues(alpha: 0.4), size: 18),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ BUDGET QUEST CARD (Glassmorphism with Mission Map)
                Container(
                  decoration: BoxDecoration(
                    color: rpgGlassLight.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.05),
                        blurRadius: 15,
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Budget Quest Card
                        FutureBuilder<double?>(
                          future: _getMonthlyBudgetLimit(),
                          builder: (context, budgetSnapshot) {
                            final budgetLimit = budgetSnapshot.data;

                            return StreamBuilder<double>(
                              stream: _getTotalExpensesStream(),
                              builder: (context, expenseSnapshot) {
                                final expense = expenseSnapshot.data ?? 0.0;

                                return _buildBudgetQuestMap(
                                  budgetLimit: budgetLimit,
                                  expense: expense,
                                );
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 24),

                        // Category Icons - Budget Breakdown
                        FutureBuilder<double?>(
                          future: _getMonthlyBudgetLimit(),
                          builder: (context, budgetSnapshot) {
                            final budgetLimit = budgetSnapshot.data;

                            return StreamBuilder<double>(
                              stream: _getTotalExpensesStream(),
                              builder: (context, expenseSnapshot) {
                                final expense = expenseSnapshot.data ?? 0.0;

                                return _buildCategoryBreakdown(budgetLimit, expense);
                              },
                            );
                          },
                        ),

                        const SizedBox(height: 20),

                        // Adjust Budget Button (Secondary Action Style)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showLimitSetupDialog,
                            icon: const Icon(Icons.edit, size: 16),
                            label: Text(
                              'Adjust Budget',
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.white.withValues(alpha: 0.3), width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // ✅ ACTION CARDS: Expenses & History (Glassmorphism)
                Row(
                  children: [
                    Expanded(
                      child: _buildGlassActionCard(
                        icon: Icons.receipt_long,
                        label: 'View Expenses',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ExpensesPage()),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildGlassActionCard(
                        icon: Icons.history,
                        label: 'History',
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('📊 Transaction history coming soon! (Shows all past expenses & income)'),
                              duration: Duration(seconds: 3),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✅ NEW: Action Card Widget with Glassmorphism
  Widget _buildGlassActionCard({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: rpgGlassLight.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.white.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Health Points Ring - RPG Style with color logic
  Widget _buildHealthPointsRing(double points) {
    final pointsInt = points.toInt();

    Color ringColor;
    if (pointsInt >= 70) {
      ringColor = rpgHealthGreen;
    } else if (pointsInt >= 30) {
      ringColor = rpgHealthYellow;
    } else {
      ringColor = rpgHealthRed;
    }

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer glow shadow
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: ringColor.withValues(alpha: 0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
          // Circular progress ring
          CustomPaint(
            size: const Size(150, 150),
            painter: HPRingPainter(
              progress: points / 100.0,
              ringColor: ringColor,
            ),
          ),
          // Center content
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '❤️',
                style: TextStyle(fontSize: 24),
              ),
              const SizedBox(height: 4),
              Text(
                '${pointsInt} HP',
                style: GoogleFonts.inter(
                  fontSize: 28,
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
                'Health Points',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.7),
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ✅ NEW: 7-Day Streak Tracker with fire icons
  Widget _buildSevenDayStreakTracker(int totalStreak) {
    // Simulate which days have streaks (in real implementation, fetch from service)
    // For demo, show filled circles for first few days
    final List<bool> streakDays = List.generate(7, (index) => index < (totalStreak % 7));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: rpgGlassLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // 7-day circles
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
              final hasFire = streakDays[index];
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: hasFire
                      ? rpgFlameOrange.withValues(alpha: 0.2)
                      : Colors.grey.withValues(alpha: 0.2),
                  border: Border.all(
                    color: hasFire
                        ? rpgFlameOrange.withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                  boxShadow: hasFire
                      ? [
                          BoxShadow(
                            color: rpgFlameOrange.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : [],
                ),
                child: Center(
                  child: Text(
                    hasFire ? '🔥' : '○',
                    style: TextStyle(
                      fontSize: 18,
                      color: hasFire ? Colors.white : Colors.grey,
                    ),
                  ),
                ),
              );
            }),
            ),
          ),
          const SizedBox(height: 16),
          // Total Streak Label
          Text(
            'Total Streak: $totalStreak Days',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ✅ NEW: Custom Painter for HP Ring
class HPRingPainter extends CustomPainter {
  final double progress;
  final Color ringColor;

  HPRingPainter({
    required this.progress,
    required this.ringColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 8;

    // Background ring
    final backgroundPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress ring
    final progressPaint = Paint()
      ..color = ringColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;

    final sweepAngle = progress * 2 * 3.14159;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      progressPaint,
    );

    // Glow effect on progress ring
    final glowPaint = Paint()
      ..color = ringColor.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -3.14159 / 2,
      sweepAngle,
      false,
      glowPaint,
    );
  }

  @override
  bool shouldRepaint(HPRingPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.ringColor != ringColor;
  }
}