import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddExpensesPage extends StatefulWidget {
  final String? expenseId;
  final Map<String, dynamic>? existingData;

  const AddExpensesPage({super.key, this.expenseId, this.existingData});

  @override
  State<AddExpensesPage> createState() => _AddExpensesPageState();
}

class _AddExpensesPageState extends State<AddExpensesPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _categoryController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  DateTime? _selectedDate;
  bool _isSaving = false;

  bool get isEditing => widget.expenseId != null;

  final CollectionReference expenses = FirebaseFirestore.instance
      .collection('users')
      .doc('local_user')
      .collection('expenses');

  @override
  void initState() {
    super.initState();
    if (isEditing && widget.existingData != null) {
      final data = widget.existingData!;
      _categoryController.text = data['category'] ?? '';
      _amountController.text = (data['amount'] is num)
          ? (data['amount'] as num).toString()
          : '';
      _noteController.text = data['note'] ?? '';
      if (data['date'] is Timestamp) {
        _selectedDate = (data['date'] as Timestamp).toDate();
      } else if (data['date'] != null) {
        _selectedDate = DateTime.tryParse(data['date'].toString());
      }
    } else {
      _selectedDate = DateTime.now();
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount.")),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final data = {
        'category': _categoryController.text.trim(),
        'amount': amount,
        'note': _noteController.text.trim(),
        'date': Timestamp.fromDate(_selectedDate!),
        'updatedAt': Timestamp.now(),
      };

      if (isEditing) {
        await expenses.doc(widget.expenseId).update(data);
      } else {
        await expenses.add({...data, 'createdAt': Timestamp.now()});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? "Expense updated successfully!"
                : "Expense added successfully!"),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF11355F);
    const Color accentBlue = Color(0xFF234A78);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F4),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(24),
            width: 360,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [primaryBlue, accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // 🔹 Logo or Icon
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 70,
                  width: 70,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Image.asset(
                      'assets/images/expense.png', // change with your asset
                      fit: BoxFit.contain,
                    ),
                  ),
                ),

                Text(
                  isEditing ? "Edit Expense" : "Add Expense",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: const Divider(color: Colors.white70, thickness: 1),
                ),
                const SizedBox(height: 10),

                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          controller: _categoryController,
                          label: "Category",
                          hint: "e.g. Food, Bills, Transport",
                          icon: Icons.category_outlined,
                          validator: (v) =>
                              v!.isEmpty ? "Please enter a category" : null,
                        ),
                        const SizedBox(height: 15),
                        _buildInputField(
                          controller: _amountController,
                          label: "Amount (RM)",
                          hint: "Enter amount",
                          icon: Icons.money_outlined,
                          inputType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return "Enter amount";
                            if (double.tryParse(v) == null) {
                              return "Invalid number format";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                        _buildDatePicker(),
                        const SizedBox(height: 15),
                        _buildInputField(
                          controller: _noteController,
                          label: "Note (optional)",
                          hint: "Add short note or description",
                          icon: Icons.note_alt_outlined,
                        ),
                        const SizedBox(height: 25),

                        GestureDetector(
                          onTap: _isSaving ? null : _saveExpense,
                          child: Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: _isSaving
                                  ? null
                                  : const LinearGradient(
                                      colors: [
                                        Color(0xFF11355F),
                                        Color(0xFF234A78)
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: _isSaving ? Colors.grey : null,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.15),
                                  blurRadius: 6,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2)
                                  : const Text(
                                      "Save Expense",
                                      style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType inputType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: inputType,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: const Color(0xFF11355F)),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF8FAFD),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF11355F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide:
              const BorderSide(color: Color(0xFF234A78), width: 1.8),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: _isSaving ? null : _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFD),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF11355F)),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_month, color: Color(0xFF11355F)),
            const SizedBox(width: 10),
            Text(
              _selectedDate == null
                  ? "Select Date"
                  : DateFormat('dd MMM yyyy').format(_selectedDate!),
              style: TextStyle(
                color:
                    _selectedDate == null ? Colors.grey : const Color(0xFF11355F),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme:
                const ColorScheme.light(primary: Color(0xFF11355F)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }
}
