import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'savings_page.dart';
import 'income_page.dart';

class AddIncomePage extends StatefulWidget {
  final String? incomeId;
  final Map<String, dynamic>? existingData;

  const AddIncomePage({super.key, this.incomeId, this.existingData});

  @override
  State<AddIncomePage> createState() => _AddIncomePageState();
}

class _AddIncomePageState extends State<AddIncomePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime? _selectedDate;
  bool _isSaving = false;
  bool _isPressed = false;

  bool get isEditing => widget.incomeId != null;

  // 🔥 Firebase reference — same path as income_page.dart
  late CollectionReference incomes;
  String? _userId;

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
    _loadEditingData();
  }

  /// Initialize Firestore with proper auth checking
  void _initializeFirestore() {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('🔍 AddIncomePage initState: user = ${user?.uid}');

    if (user == null) {
      debugPrint('⚠️ User not authenticated in AddIncomePage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be signed in to add income'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      return;
    }

    _userId = user.uid;

    // Initialize reference to users/{uid}/income (matches income_page.dart & home_page.dart)
    incomes = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('income');

    debugPrint(
        '✅ AddIncomePage Firestore path initialized: users/${user.uid}/income');
  }

  /// Load existing data if editing
  void _loadEditingData() {
    if (isEditing && widget.existingData != null) {
      final data = widget.existingData!;
      _categoryController.text = data['category'] ?? '';
      _amountController.text =
          (data['amount'] is num) ? (data['amount']).toString() : '';
      _noteController.text = data['note'] ?? '';

      if (data['date'] is Timestamp) {
        _selectedDate = (data['date'] as Timestamp).toDate();
        debugPrint('📅 Loaded existing date: $_selectedDate');
      } else if (data['date'] != null) {
        _selectedDate = DateTime.tryParse(data['date'].toString());
      }

      debugPrint(
          '✏️ Loaded existing income for editing: ${data['category']} - RM${data['amount']}');
    } else {
      _selectedDate = DateTime.now();
    }
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Save income to Firestore
  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ Form validation failed');
      return;
    }

    // Validate amount
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid amount.")),
        );
      }
      debugPrint('❌ Invalid amount: $amount');
      return;
    }

    // Validate date
    if (_selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a date.")),
        );
      }
      debugPrint('❌ No date selected');
      return;
    }

    // Check user is still authenticated
    if (_userId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Authentication expired. Please login again.")),
        );
      }
      debugPrint('❌ User ID is null');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final category = _categoryController.text.trim();
      final note = _noteController.text.trim();

      // Data to save (matches income_page.dart expectations)
      final data = {
        'category': category,
        'amount': amount,
        'note': note,
        'date': Timestamp.fromDate(_selectedDate!),
        'updatedAt': Timestamp.now(),
      };

      if (isEditing) {
        // UPDATE existing income
        debugPrint(
            '📝 Updating income ${widget.incomeId}: $category - RM$amount on $_selectedDate');

        await incomes.doc(widget.incomeId).update(data);

        debugPrint(
            '✅ Income updated successfully: users/$_userId/income/${widget.incomeId}');
      } else {
        // ADD new income
        debugPrint(
            '➕ Adding new income: $category - RM$amount on $_selectedDate');

        final docRef = await incomes.add({
          ...data,
          'createdAt': Timestamp.now(),
        });

        debugPrint(
            '✅ Income added successfully: users/$_userId/income/${docRef.id}');
      }

      if (mounted) {
        if (isEditing) {
          // For editing, just show a snackbar and pop
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Income updated successfully!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Small delay to let Firestore sync before popping
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) Navigator.pop(context);
        } else {
          // For new income, show confirmation popup
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("✅ Income added successfully!"),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Small delay to let Firestore sync
          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            _showIncomeConfirmation();
          }
        }
      }
    } on FirebaseException catch (e) {
      debugPrint('🔥 Firebase error: ${e.code} - ${e.message}');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e, st) {
      debugPrint('❌ Unexpected error: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Show confirmation popup for new income
  Future<void> _showIncomeConfirmation() async {
    final shouldNavigateToSavings = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '',
      transitionDuration: const Duration(milliseconds: 280),
      pageBuilder: (_, __, ___) => const SizedBox.shrink(),
      transitionBuilder: (context, animation, secondary, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
        );

        return Transform.scale(
          scale: curved.value,
          child: Opacity(
            opacity: animation.value,
            child: Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated Icon
                    Transform.scale(
                      scale: 0.85 + curved.value * 0.15,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFF58C5FF).withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.savings_rounded,
                          color: Color(0xFF58C5FF),
                          size: 46,
                        ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      "Save to Savings?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Text(
                      "Would you like to save this income to your savings account?",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.black54,
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        // Skip Button
                        Expanded(
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: Colors.grey),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(
                              "Skip",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Save to Savings Button
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF58C5FF),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(
                              "Yes",
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    ) ?? false;

    // Handle navigation based on user choice
    if (!mounted) return;

    if (shouldNavigateToSavings) {
      // Navigate to savings page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SavingsPage()),
      );
    } else {
      // Navigate back to income page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const IncomePage()),
      );
    }
  }

  /// Date Picker
  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF11355F),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
      debugPrint('📅 Date selected: $_selectedDate');
    }
  }

  /// Custom Input Field Widget
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

  /// Date Picker Widget
  Widget _buildDatePicker() {
    final displayDate = _selectedDate == null
        ? "Select Date"
        : DateFormat('dd MMMM yyyy').format(_selectedDate!);

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
          onTap: _isSaving ? null : _pickDate,
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
                      color: _selectedDate == null
                          ? Colors.grey.shade400
                          : const Color(0xFF1A202C),
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

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF11355F);
    const Color accentBlue = Color(0xFF2A466F);
    const Color neonBlue = Color(0xFF58C5FF);
    const Color violet = Color(0xFF7C5CFF);
    const Color coral = Color(0xFFFF7A59);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD),
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
        title: Text(
          isEditing ? "Edit Income ✏️" : "New Income 💸",
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
                  colors: [primaryBlue, accentBlue],
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
                              Icons.trending_up_rounded,
                              color: primaryBlue,
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? "Update your win" : "Track your income",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isEditing
                                      ? "Fine-tune the details"
                                      : "Every amount counts!",
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
                        _buildInputField(
                          controller: _categoryController,
                          label: "Category",
                          hint: "e.g. Salary, Bonus, Freelance",
                          icon: Icons.label_outline,
                          validator: (v) =>
                              v!.isEmpty ? "Please enter a category" : null,
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

                        // Animated Gradient Save Button
                        GestureDetector(
                          onTapDown: (_) =>
                              setState(() => _isPressed = true),
                          onTapCancel: () =>
                              setState(() => _isPressed = false),
                          onTapUp: (_) => setState(() => _isPressed = false),
                          onTap: _isSaving ? null : _saveIncome,
                          child: AnimatedScale(
                            scale: _isPressed && !_isSaving ? 0.96 : 1.0,
                            duration: const Duration(milliseconds: 100),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              width: double.infinity,
                              height: 62,
                              decoration: BoxDecoration(
                                gradient: _isSaving
                                    ? LinearGradient(
                                        colors: [
                                          Colors.grey.shade400,
                                          Colors.grey.shade500,
                                        ],
                                      )
                                    : const LinearGradient(
                                        colors: [
                                          neonBlue,
                                          violet,
                                          coral,
                                        ],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: (neonBlue).withAlpha((0.40 * 255).round()),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isSaving
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            isEditing
                                                ? "Update Income"
                                                : "Save Income",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 18,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 22,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                        if (!isKeyboardOpen) const SizedBox(height: 40),
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