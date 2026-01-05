import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'services/gamification_service.dart';

const _primary = Color(0xFF3C79C1); // Vibrant Light Blue
const _accent = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple

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
        borderRadius: BorderRadius.circular(18.0),
        gradient: const LinearGradient(
          colors: [_primary, _accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _primary.withAlpha((0.40 * 255).round()),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(18.0),
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

  /// Custom Input Field Widget (matching add_income_page style)
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
              fontSize: 14,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: inputType,
          style: const TextStyle(
            color: Color(0xFF1A202C),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: const Color(0xFF58C5FF), size: 20),
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: const Color(0xFFF7FAFC),
            contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFF58C5FF),
                width: 2.0,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(
                color: Color(0xFFFF6B6B),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Date Picker Widget (matching add_income_page style)
  Widget _buildDatePicker() {
    final displayDate = _selectedDate == DateTime.now()
        ? "Select Date"
        : DateFormat('dd MMMM yyyy').format(_selectedDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "Date",
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF2D3748),
              fontSize: 14,
            ),
          ),
        ),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF7FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: const Color(0xFFE2E8F0),
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_today,
                  color: Color(0xFF58C5FF),
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayDate,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [_primary, _accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          widget.existingId != null ? "Edit Expense ✏️" : "New Expense 💸",
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_primary, _accent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha((0.15 * 255).round()),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -30,
                    top: -40,
                    child: Container(
                      height: 140,
                      width: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withAlpha((0.08 * 255).round()),
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha((0.95 * 255).round()),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(
                              Icons.money_off_rounded,
                              color: _primary,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.existingId != null ? "Update your record" : "Track your spending",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.existingId != null
                                      ? "Fine-tune the details"
                                      : "Every expense counts!",
                                  style: TextStyle(
                                    color: Colors.white.withAlpha((0.82 * 255).round()),
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Form
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha((0.08 * 255).round()),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Category Field
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 4, bottom: 8),
                              child: Text(
                                "Category",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF2D3748),
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF7FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFFE2E8F0),
                                  width: 1.5,
                                ),
                              ),
                              child: DropdownButtonFormField<String>(
                                value: _category,
                                decoration: const InputDecoration(
                                  contentPadding: EdgeInsets.zero,
                                  border: InputBorder.none,
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
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildInputField(
                          controller: _amountController,
                          label: "Amount (RM)",
                          hint: "0.00",
                          icon: Icons.attach_money,
                          inputType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return "Enter amount";
                            if (double.tryParse(v) == null) {
                              return "Invalid number format";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildDatePicker(),
                        const SizedBox(height: 18),
                        _buildInputField(
                          controller: _noteController,
                          label: "Note (optional)",
                          hint: "Add a brief note",
                          icon: Icons.edit_note,
                        ),
                        const SizedBox(height: 32),
                        _buildGradientButton(
                          text: widget.existingId != null ? 'UPDATE EXPENSE' : 'SAVE EXPENSE',
                          onPressed: _saveExpense,
                        ),
                        const SizedBox(height: 40),
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