// lib/services/gamification_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class GamificationService {
  static const int initialPoints = 100;
  static const double deductionPerRM10 = 5.0;
  static const double maxDeductionPerIncident = 50.0;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get or initialize user gamification data
  /// ✅ UPDATED: Returns whether this is a NEW initialization
  Future<Map<String, dynamic>> getOrInitializeUserGamification() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _firestore.collection('users').doc(user.uid);
    final gamificationRef = docRef.collection('gamification').doc('stats');

    final snapshot = await gamificationRef.get();

    if (snapshot.exists) {
      final data = snapshot.data() as Map<String, dynamic>;
      data['isNewInit'] = false; // Existing user
      return data;
    }

    
    final newData = {
      'totalPoints': initialPoints,
      'currentMonthPoints': initialPoints,
      'monthYear': _getCurrentMonthYear(),
      'createdAt': FieldValue.serverTimestamp(),
      'pointDeductions': [],
      'pointAdditions': [],
      'lastResetDate': FieldValue.serverTimestamp(),
      'currentStreak': 0, 
      'longestStreak': 0, 
      'lastLoginDate': null, 
      'isNewInit': true, 
    };

    await gamificationRef.set(newData);
    debugPrint('🎉 NEW USER: Initialized with $initialPoints points');
    return newData;
  }

  Future<double> getCurrentMonthPoints() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('stats');

    final snapshot = await docRef.get();
    if (!snapshot.exists) {
      await getOrInitializeUserGamification();
      return initialPoints.toDouble();
    }

    final data = snapshot.data() as Map<String, dynamic>;
    return (data['currentMonthPoints'] as num?)?.toDouble() ?? initialPoints.toDouble();
  }

  Future<Map<String, dynamic>?> checkOverspending({
    required double totalMonthlyExpense,
    required double monthlyBudgetLimit,
  }) async {
    if (totalMonthlyExpense <= monthlyBudgetLimit) {
      return null;
    }

    final overspentAmount = totalMonthlyExpense - monthlyBudgetLimit;
    final deductionAmount = _calculateDeduction(overspentAmount);

    return {
      'overspentAmount': overspentAmount,
      'deductionAmount': deductionAmount,
      'budgetLimit': monthlyBudgetLimit,
      'totalExpense': totalMonthlyExpense,
    };
  }

  /// ✅ FIXED: Better deduction logic without FieldValue in map
  Future<void> deductPoints({
    required double amount,
    required String reason,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('stats');

    try {
      final snapshot = await docRef.get();
      if (!snapshot.exists) {
        await getOrInitializeUserGamification();
        return;
      }

      final data = snapshot.data() as Map<String, dynamic>;
      double currentPoints = (data['currentMonthPoints'] as num?)?.toDouble() ?? initialPoints.toDouble();
      double totalPoints = (data['totalPoints'] as num?)?.toDouble() ?? initialPoints.toDouble();

      debugPrint('🔍 Before deduction: $currentPoints SP');

      // Calculate new points
      final newCurrentPoints = (currentPoints - amount).clamp(0.0, 1000.0);
      final newTotalPoints = (totalPoints - amount).clamp(0.0, 1000.0);

      // Only update if points actually changed
      if (newCurrentPoints == currentPoints) {
        debugPrint('⚠️ Points already at target level: $currentPoints SP');
        return;
      }

      debugPrint('💳 Deducting $amount SP: $currentPoints -> $newCurrentPoints SP');

      // ✅ Build deduction record WITHOUT FieldValue (will add timestamp in update)
      final deduction = {
        'amount': amount,
        'reason': reason,
        'pointsAfter': newCurrentPoints,
        'timestamp': Timestamp.now(),  // ✅ Use Timestamp.now() instead of FieldValue
      };

      // Update Firestore
      await docRef.update({
        'currentMonthPoints': newCurrentPoints,
        'totalPoints': newTotalPoints,
        'pointDeductions': FieldValue.arrayUnion([deduction]),
      });
      
      debugPrint('✅ Deduction saved: New balance = $newCurrentPoints SP');
    } catch (e) {
      debugPrint('❌ Error deducting points: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDeductionHistory() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('stats');

    final snapshot = await docRef.get();
    if (!snapshot.exists) return [];

    final data = snapshot.data() as Map<String, dynamic>;
    final deductions = data['pointDeductions'] as List<dynamic>? ?? [];

    return deductions.cast<Map<String, dynamic>>();
  }

  Stream<double> getCurrentMonthPointsStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('stats')
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            getOrInitializeUserGamification();
            return initialPoints.toDouble();
          }
          final data = snapshot.data() as Map<String, dynamic>;
          final points = (data['currentMonthPoints'] as num?)?.toDouble() ?? initialPoints.toDouble();
          debugPrint('🎮 GamificationService Stream: currentMonthPoints = $points SP');
          return points;
        });
  }

  Future<void> resetMonthlyPoints() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final docRef = _firestore
        .collection('users')
        .doc(user.uid)
        .collection('gamification')
        .doc('stats');

    await docRef.update({
      'currentMonthPoints': initialPoints,
      'monthYear': _getCurrentMonthYear(),
      'lastResetDate': FieldValue.serverTimestamp(),
      'pointDeductions': [],
    });
  }

  double _calculateDeduction(double overspentAmount) {
    final rawDeduction = (overspentAmount / 10).ceil() * deductionPerRM10;
    return rawDeduction.clamp(0.0, maxDeductionPerIncident);
  }

  String _getCurrentMonthYear() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  /// Add points for maintaining streak
Future<void> addPoints({
  required double amount,
  required String reason,
}) async {
  final user = _auth.currentUser;
  if (user == null) throw Exception('User not authenticated');

  final gamificationRef = _firestore
      .collection('users')
      .doc(user.uid)
      .collection('gamification')
      .doc('stats');

  await _firestore.runTransaction((transaction) async {
    final snapshot = await transaction.get(gamificationRef);
    
    if (!snapshot.exists) {
      throw Exception('Gamification data not found');
    }

    final data = snapshot.data()!;
    final currentPoints = (data['currentMonthPoints'] as num).toDouble();
    final totalPoints = (data['totalPoints'] as num).toDouble();
    final pointAdditions = List<Map<String, dynamic>>.from(data['pointAdditions'] ?? []);

    // Add new points
    final newCurrentPoints = currentPoints + amount;
    final newTotalPoints = totalPoints + amount;

    // Log the addition (✅ Use Timestamp.now() instead of FieldValue.serverTimestamp())
    pointAdditions.add({
      'amount': amount,
      'reason': reason,
      'timestamp': Timestamp.now(),  // ✅ Fixed: Use Timestamp.now() in maps
    });

    transaction.update(gamificationRef, {
      'currentMonthPoints': newCurrentPoints,
      'totalPoints': newTotalPoints,
      'pointAdditions': pointAdditions,
      'lastUpdated': FieldValue.serverTimestamp(),
    });

    debugPrint('✅ Added $amount SP for: $reason');
    debugPrint('   New Points: $newCurrentPoints SP');
  });
}

/// Check and update daily streak
Future<Map<String, dynamic>> checkAndUpdateStreak() async {
  final user = _auth.currentUser;
  if (user == null) throw Exception('User not authenticated');

  final gamificationRef = _firestore
      .collection('users')
      .doc(user.uid)
      .collection('gamification')
      .doc('stats');

  final snapshot = await gamificationRef.get();
  if (!snapshot.exists) {
    throw Exception('Gamification data not found');
  }

  final data = snapshot.data()!;
  final lastLoginTimestamp = data['lastLoginDate'] as Timestamp?;
  final currentStreak = (data['currentStreak'] as num?)?.toInt() ?? 0;
  final longestStreak = (data['longestStreak'] as num?)?.toInt() ?? 0;

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);

  // First time or no last login
  if (lastLoginTimestamp == null) {
    await gamificationRef.update({
      'lastLoginDate': Timestamp.fromDate(today),
      'currentStreak': 1,
      'longestStreak': 1,
    });

    await addPoints(amount: 2, reason: 'daily_login_day_1');
    
    return {
      'isNewStreak': true,
      'currentStreak': 1,
      'pointsEarned': 2.0,
      'bonusEarned': 0.0,
    };
  }

  final lastLogin = lastLoginTimestamp.toDate();
  final lastLoginDay = DateTime(lastLogin.year, lastLogin.month, lastLogin.day);
  final daysDifference = today.difference(lastLoginDay).inDays;

  // Same day - no points
  if (daysDifference == 0) {
    return {
      'isNewStreak': false,
      'currentStreak': currentStreak,
      'pointsEarned': 0.0,
      'bonusEarned': 0.0,
      'message': 'Already logged in today!',
    };
  }

  int newStreak = currentStreak;
  double pointsEarned = 2.0;
  double bonusEarned = 0.0;

  // Consecutive day - increment streak
  if (daysDifference == 1) {
    newStreak = currentStreak + 1;
    
    // Check for streak bonuses
    if (newStreak == 7) {
      bonusEarned = 5.0;
      await addPoints(amount: bonusEarned, reason: '7_day_streak_bonus');
    } else if (newStreak == 30) {
      bonusEarned = 20.0;
      await addPoints(amount: bonusEarned, reason: '30_day_streak_bonus');
    }
  } 
  // Streak broken - reset to 1
  else {
    newStreak = 1;
  }

  // Update Firestore
  await gamificationRef.update({
    'lastLoginDate': Timestamp.fromDate(today),
    'currentStreak': newStreak,
    'longestStreak': newStreak > longestStreak ? newStreak : longestStreak,
  });

  // Award daily points
  await addPoints(amount: pointsEarned, reason: 'daily_login_day_$newStreak');

  return {
    'isNewStreak': daysDifference > 1,
    'currentStreak': newStreak,
    'pointsEarned': pointsEarned,
    'bonusEarned': bonusEarned,
  };
}

/// Get current streak
Future<int> getCurrentStreak() async {
  final user = _auth.currentUser;
  if (user == null) return 0;

  final snapshot = await _firestore
      .collection('users')
      .doc(user.uid)
      .collection('gamification')
      .doc('stats')
      .get();

  if (!snapshot.exists) return 0;
  return (snapshot.data()?['currentStreak'] as num?)?.toInt() ?? 0;
} 
}