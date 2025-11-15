import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

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

  bool get isEditing => widget.incomeId != null;

  final CollectionReference incomes = FirebaseFirestore.instance
      .collection('users')
      .doc('local_user')
      .collection('income');

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

  @override
  void dispose() {
    _categoryController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  // --- Save Logic ---
  Future<void> _saveIncome() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please enter a valid amount.")),
        );
      }
      return;
    }
    
    if (_selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please select a date.")),
        );
      }
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
        await incomes.doc(widget.incomeId).update(data);
      } else {
        await incomes.add({...data, 'createdAt': Timestamp.now()});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEditing
                ? "Income updated successfully!"
                : "Income added successfully!"),
          ),
        );
        Navigator.pop(context);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // --- Date Picker Logic ---
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

  // --- Custom Input Field Widget (Enhanced) ---
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
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            label,
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: inputType,
          style: const TextStyle(color: Color(0xFF11355F)),
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 20),
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF11355F), width: 2.0),
            ),
          ),
        ),
      ],
    );
  }

  // --- Date Picker Widget (Enhanced) ---
  Widget _buildDatePicker() {
    final displayDate = _selectedDate == null
        ? "Select Date"
        : DateFormat('dd MMMM yyyy').format(_selectedDate!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 4),
          child: Text(
            "Date",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: Colors.grey.shade700),
          ),
        ),
        GestureDetector(
          onTap: _isSaving ? null : _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300, width: 1.0),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.grey.shade500, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    displayDate,
                    style: TextStyle(
                      color: _selectedDate == null
                          ? Colors.grey.shade400
                          : const Color(0xFF11355F),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
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


  // --- Main Build Method (Redesigned) ---
  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF11355F);
    const Color accentBlue = Color(0xFF345A8B);
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFD), 
      appBar: AppBar(
        title: Text(
          isEditing ? "Edit Income ✏️" : "New Income 💸",
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
        toolbarHeight: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 1. Gradient Header with Icon
            Container(
              padding: const EdgeInsets.fromLTRB(24, 40, 24, 60),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [primaryBlue, accentBlue],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 15,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back Button 
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 30,
                        child: Icon(Icons.attach_money_rounded,
                            color: primaryBlue, size: 30),
                      ),
                      const SizedBox(width: 15),
                      Text(
                        isEditing ? "Modify Income Entry" : "Record New Income",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // 2. Form Container 
            Transform.translate(
              offset: const Offset(0, -30),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFD),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
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
                          hint: "e.g. Salary, Allowance",
                          icon: Icons.label_outline,
                          validator: (v) =>
                              v!.isEmpty ? "Please enter a category" : null,
                        ),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _amountController,
                          label: "Amount (RM)",
                          hint: "0.00",
                          icon: Icons.money,
                          inputType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return "Enter amount";
                            if (double.tryParse(v) == null) {
                              return "Invalid number format";
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildDatePicker(),
                        const SizedBox(height: 20),
                        _buildInputField(
                          controller: _noteController,
                          label: "Note (optional)",
                          hint: "Short description of income source",
                          icon: Icons.edit_note,
                        ),
                        const SizedBox(height: 30),

                        // 3. Save Button (Green Gradient for Income)
                        GestureDetector(
                          onTap: _isSaving ? null : _saveIncome,
                          child: Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              gradient: _isSaving
                                  ? null
                                  : const LinearGradient(
                                      colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)], 
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                              color: _isSaving ? Colors.grey : null,
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Center(
                              child: _isSaving
                                  ? const CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2)
                                  : Text(
                                      isEditing ? "UPDATE INCOME" : "SAVE INCOME",
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18),
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