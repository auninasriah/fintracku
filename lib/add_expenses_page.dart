import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/gamification_service.dart';

const _primary = Color.fromARGB(255, 105, 158, 218); 
const _accent = Color(0xFF234A78);

class AddExpensePage extends StatefulWidget {
  final String? existingId;
  final Map<String, dynamic>? existingData;

  const AddExpensePage({super.key, this.existingId, this.existingData});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  late CollectionReference expensesCol;
  late GamificationService _gamificationService;

  late TextEditingController _amountController;
  late TextEditingController _noteController;
  String _category = 'Others';
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    'Food & Drink',
    'Transport',
    'Bills',
    'Shopping',
    'Health',
    'Others'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
    _initializeControllers();
    _gamificationService = GamificationService();
  }

  void _initializeFirestore() {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('🔍 AddExpensePage initState: user = ${user?.uid}');

    if (user == null) {
      debugPrint('⚠️ User not authenticated in AddExpensePage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be signed in to add expenses'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      return;
    }

    expensesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('expenses');

    debugPrint('✅ AddExpensePage Firestore path initialized: users/${user.uid}/expenses');
  }

  void _initializeControllers() {
    _amountController = TextEditingController(
      text: widget.existingData != null
          ? widget.existingData!['amount'].toString()
          : '',
    );

    _noteController = TextEditingController(
      text: widget.existingData != null
          ? widget.existingData!['note'] ?? ''
          : '',
    );

    _category = widget.existingData != null
        ? widget.existingData!['category'] ?? 'Others'
        : 'Others';

    _selectedDate = widget.existingData != null
        ? (widget.existingData!['date'] is Timestamp
            ? (widget.existingData!['date'] as Timestamp).toDate()
            : DateTime.tryParse(widget.existingData!['date'].toString()) ??
                DateTime.now())
        : DateTime.now();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<double> _getMonthlyBudgetLimit() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 500.0;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('budget')
          .get();

      return (doc.data()?['monthlyLimit'] as num?)?.toDouble() ?? 500.0;
    } catch (e) {
      debugPrint('❌ Error fetching budget limit: $e');
      return 500.0;
    }
  }

  Future<double> _getTotalMonthlyExpenses() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 0.0;

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

    try {
      final snapshot = await expensesCol
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
      debugPrint('❌ Error calculating total expenses: $e');
      return 0.0;
    }
  }

  /// ✅ Fixed: Replaced withOpacity with withValues
  void _showOverspendingAlert(Map<String, dynamic> overspendData) {
    final overspentAmount = (overspendData['overspentAmount'] as num).toDouble();
    final deductionAmount = (overspendData['deductionAmount'] as num).toDouble();
    final currentPoints = (overspendData['currentPoints'] as num).toDouble();
    final newPoints = currentPoints - deductionAmount;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('🚨 OVERSPENDING ALERT!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                // ✅ FIXED: Changed from withOpacity(0.1) to withValues(alpha: 0.1)
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
                // ✅ FIXED: Changed from withOpacity(0.1) to withValues(alpha: 0.1)
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
              '💡 Tip: Try reducing expenses in the upcoming days to get back on track!',
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

  Future<void> _checkOverspendingAndNotify() async {
    try {
      final budgetLimit = await _getMonthlyBudgetLimit();
      final currentExpenses = await _getTotalMonthlyExpenses();
      
      final newExpenseAmount = double.tryParse(_amountController.text) ?? 0;
      final totalWithNewExpense = currentExpenses + newExpenseAmount;

      debugPrint('📊 Budget Check: Limit=$budgetLimit, Current=$currentExpenses, New=$newExpenseAmount, Total=$totalWithNewExpense');

      final overspendData = await _gamificationService.checkOverspending(
        totalMonthlyExpense: totalWithNewExpense,
        monthlyBudgetLimit: budgetLimit,
      );

      if (overspendData != null) {
        final currentPoints = await _gamificationService.getCurrentMonthPoints();
        final deductionAmount = overspendData['deductionAmount'] as double;

        await _gamificationService.deductPoints(
          amount: deductionAmount,
          reason: 'overspent_rm${overspendData['overspentAmount'].toStringAsFixed(2)}',
        );

        overspendData['currentPoints'] = currentPoints;

        if (mounted) {
          _showOverspendingAlert(overspendData);
          debugPrint('🚨 Overspending detected! Points deducted: $deductionAmount');
        }
      } else {
        debugPrint('✅ No overspending detected');
      }
    } catch (e) {
      debugPrint('❌ Error checking overspending: $e');
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;

    final double amount = double.tryParse(_amountController.text) ?? 0;
    final String note = _noteController.text;

    final data = {
      'amount': amount,
      'category': _category,
      'note': note,
      'date': _selectedDate,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.existingId != null) {
        await expensesCol.doc(widget.existingId).update(data);
        debugPrint('✅ Expense updated: ${widget.existingId}');
      } else {
        final docRef = await expensesCol.add(data);
        debugPrint('✅ Expense added: ${docRef.id}');
      }

      await _checkOverspendingAndNotify();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.existingId != null ? 'Expense updated' : 'Expense added'),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error saving expense: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2022),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Widget _buildGradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        gradient: LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(10.0),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required TextInputType keyboardType,
    String? Function(String?)? validator,
    String? labelText,
    Widget? prefixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 16),
      decoration: InputDecoration(
        hintText: hintText,
        labelText: labelText,
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: _primary, width: 2),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _accent,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(''),
          centerTitle: false, 
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 0, bottom: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      // ✅ FIXED: Changed from withOpacity(0.2) to withValues(alpha: 0.2)
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.money_off, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    widget.existingId != null ? 'Edit Expense' : 'Record New Expense',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Category', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.zero,
                              border: InputBorder.none,
                              hintText: 'e.g. Food & Drink, Transport',
                              hintStyle: TextStyle(color: Colors.grey),
                            ),
                            items: _categories
                                .map((cat) => DropdownMenuItem(
                                      value: cat,
                                      child: Text(cat),
                                    ))
                                .toList(),
                            onChanged: (val) => setState(() {
                              _category = val!;
                            }),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Amount (RM)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        _buildTextField(
                          controller: _amountController,
                          hintText: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: const Icon(Icons.money),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter amount';
                            if (double.tryParse(value) == null) return 'Enter valid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        Text('Date', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.transparent),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.calendar_today, color: Colors.grey),
                                const SizedBox(width: 10),
                                Text(
                                  DateFormat('dd MMMM yyyy').format(_selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('Note (optional)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        _buildTextField(
                          controller: _noteController,
                          hintText: 'Short description of expense source...',
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 32),
                        _buildGradientButton(
                          text: widget.existingId != null ? 'UPDATE EXPENSE' : 'SAVE EXPENSE',
                          onPressed: _saveExpense,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}