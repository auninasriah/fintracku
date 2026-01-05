import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Model for expense insight
class ExpenseInsight {
  final String message;
  final String suggestion;
  final bool hasRepeatedSpending;
  final String? category;
  final String? merchantName;
  final int count;
  final double totalAmount;

  ExpenseInsight({
    required this.message,
    required this.suggestion,
    required this.hasRepeatedSpending,
    this.category,
    this.merchantName,
    this.count = 0,
    this.totalAmount = 0.0,
  });
}

/// Service for generating rule-based expense insights
class InsightService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get current week number for a given date
  int _getWeekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final difference = date.difference(startOfYear).inDays;
    return (difference / 7).ceil();
  }

  /// Group expenses by week, category, and note
  Future<Map<String, dynamic>> _groupExpensesByWeek() async {
    final user = _auth.currentUser;
    if (user == null) return {};

    final now = DateTime.now();
    final currentWeekNumber = _getWeekNumber(now);
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    print('📥 [Insight] Fetching expenses from ${startOfMonth.toLocal()} to ${endOfMonth.toLocal()}');
    print('📥 [Insight] Current week number: $currentWeekNumber');

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('expenses')
          .where('timestamp', isGreaterThanOrEqualTo: startOfMonth)
          .where('timestamp', isLessThanOrEqualTo: endOfMonth)
          .get();

      print('📥 [Insight] Found ${snapshot.docs.length} expenses');

      // Group by week → category → note
      final groupedData = <int, Map<String, Map<String, List<double>>>>{};

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final weekNumber = _getWeekNumber(timestamp);
        final category = data['category']?.toString() ?? 'Uncategorized';
        final note = data['note']?.toString() ?? data['merchant']?.toString() ?? 'No note';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        print('📥 [Insight] Expense: $note ($category), Amount: $amount, Date: ${timestamp.toLocal()}, Week: $weekNumber');

        // Initialize nested maps
        groupedData.putIfAbsent(weekNumber, () => {});
        groupedData[weekNumber]!.putIfAbsent(category, () => {});
        groupedData[weekNumber]![category]!.putIfAbsent(note, () => []);

        // Add amount to list
        groupedData[weekNumber]![category]![note]!.add(amount);
      }

      print('📥 [Insight] Grouped data by week: ${groupedData.keys}');
      return {
        'grouped': groupedData,
        'currentWeek': currentWeekNumber,
      };
    } catch (e) {
      print('❌ Error grouping expenses: $e');
      return {};
    }
  }

  /// Detect repeated spending patterns (Rule: count ≥ 2 in same week)
  Future<ExpenseInsight> detectRepeatedSpending() async {
    try {
      final groupedResult = await _groupExpensesByWeek();
      final groupedData =
          (groupedResult['grouped'] as Map<dynamic, dynamic>?) ?? {};
      final currentWeek = groupedResult['currentWeek'] as int? ?? 0;

      print('📊 [Insight] Grouped Data: $groupedData');
      print('📊 [Insight] Current Week: $currentWeek');

      if (groupedData.isEmpty || currentWeek == 0) {
        print('❌ [Insight] No data or invalid week');
        return _balancedSpendingInsight();
      }

      // Get current week's data
      final currentWeekData =
          (groupedData[currentWeek] as Map<dynamic, dynamic>?) ?? {};

      print('📊 [Insight] Current Week Data: $currentWeekData');

      if (currentWeekData.isEmpty) {
        print('❌ [Insight] No expenses in current week');
        return _balancedSpendingInsight();
      }

      // Find repeated category + note combinations
      String? topMerchant;
      String? topCategory;
      int maxCount = 0;
      double totalAmount = 0.0;

      currentWeekData.forEach((category, notes) {
        final notesMap = notes as Map<dynamic, dynamic>;
        notesMap.forEach((note, amounts) {
          final amountsList = amounts as List<double>;
          print('📊 [Insight] Category: $category, Note: $note, Count: ${amountsList.length}, Amounts: $amountsList');
          if (amountsList.length >= 2 && amountsList.length > maxCount) {
            maxCount = amountsList.length;
            topMerchant = note.toString();
            topCategory = category.toString();
            totalAmount = amountsList.fold(0.0, (sum, amt) => sum + amt);
            print('✅ [Insight] New top: $topMerchant ($maxCount times, RM$totalAmount)');
          }
        });
      });

      // Rule triggered: count ≥ 2
      if (maxCount >= 2 && topMerchant != null && topCategory != null) {
        print('✅ [Insight] Repeated spending detected!');
        return _repeatedSpendingInsight(
          merchant: topMerchant!,
          category: topCategory!,
          count: maxCount,
          totalAmount: totalAmount,
        );
      }

      print('ℹ️ [Insight] No repeated spending found (max count: $maxCount)');
      return _balancedSpendingInsight();
    } catch (e, st) {
      print('❌ Error detecting repeated spending: $e');
      print('Stack trace: $st');
      return _balancedSpendingInsight();
    }
  }

  /// Generate insight for repeated spending
  ExpenseInsight _repeatedSpendingInsight({
    required String merchant,
    required String category,
    required int count,
    required double totalAmount,
  }) {
    return ExpenseInsight(
      message:
          '💡 You visited "$merchant" $count times this week (RM${totalAmount.toStringAsFixed(2)})',
      suggestion:
          '👉 Consider limiting ${category.toLowerCase()} spending to 2 times per week.',
      hasRepeatedSpending: true,
      category: category,
      merchantName: merchant,
      count: count,
      totalAmount: totalAmount,
    );
  }

  /// Generate insight for balanced spending
  ExpenseInsight _balancedSpendingInsight() {
    return ExpenseInsight(
      message: '💡 Your spending looks balanced this week. Keep it up!',
      suggestion: '✨ Great job maintaining good spending habits.',
      hasRepeatedSpending: false,
    );
  }
}
