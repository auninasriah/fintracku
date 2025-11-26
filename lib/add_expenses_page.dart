import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';   // ✅ ADDED

// Your existing color constants
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

  // ✅ NEW — FIXED (declare only)
  late CollectionReference expensesCol;

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

    // ✅ Initialize Firestore with Auth user
    final user = FirebaseAuth.instance.currentUser;

    expensesCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user?.uid ?? "null_user")
        .collection('expenses');

    // 🟦 Your existing initState logic (unchanged)
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
        await expensesCol.doc(widget.existingId).update(data); // EDIT
      } else {
        await expensesCol.add(data); // ADD
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.existingId != null ? 'Expense updated' : 'Expense added'),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
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

  // Helper for the custom button
  Widget _buildGradientButton({required String text, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0), // More corner radius
        gradient: LinearGradient(
          colors: [
            _primary, // Light Blue
            _accent,  // Dark Blue
          ],
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

  // Helper for text fields to match the design (no label text, just hint/placeholder)
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
        labelText: labelText, // Keep labelText for category and amount for better UX
        prefixIcon: prefixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        filled: true,
        fillColor: Colors.grey[100],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none, // Hide border to match the design's input fields
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.0),
          borderSide: BorderSide(color: _primary, width: 2), // Slight highlight on focus
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold is wrapped in a Container to achieve the dark blue background
    return Container(
      color: _accent, // Dark blue background for the entire screen
      child: Scaffold(
        backgroundColor: Colors.transparent, // Make Scaffold body transparent
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(''), // Removed text from AppBar title
          centerTitle: false, 
        ),
        body: Column(
          children: [
            // Icon and title for 'Record New Expense' (KEPT THIS SECTION)
            Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 0, bottom: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // Light icon background
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
                // The white card background
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
                        // Category Dropdown
                        Text('Category', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[100], // Light background for input field
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButtonFormField<String>(
                            value: _category,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.zero, // Remove inner padding
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

                        // Amount Text Field
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

                        // Date Picker Field
                        Text('Date', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border.all(color: Colors.transparent), // Added for visual boundary
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

                        // Note Text Field
                        Text('Note (optional)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        _buildTextField(
                          controller: _noteController,
                          hintText: 'Short description of expense source...',
                          keyboardType: TextInputType.text,
                        ),
                        const SizedBox(height: 32),

                        // Save/Update Button (Gradient and rounded)
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