import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const _primary = Color.fromARGB(255, 105, 158, 218); 
const _accent = Color(0xFF3C79C1); // Vibrant Light Blue

class AddSavingsPage extends StatefulWidget {
  final String? existingId;
  final Map<String, dynamic>? existingData;

  const AddSavingsPage({super.key, this.existingId, this.existingData});

  @override
  State<AddSavingsPage> createState() => _AddSavingsPageState();
}

class _AddSavingsPageState extends State<AddSavingsPage> {
  final _formKey = GlobalKey<FormState>();
  late CollectionReference savingsGoalsCol;

  late TextEditingController _nameController;
  late TextEditingController _targetController;
  String _category = 'Emergency';

  final List<String> _categories = [
    'Emergency',
    'Travel',
    'House',
    'Wedding',
    'Car',
    'Education'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFirestore();
    _initializeControllers();
  }

  void _initializeFirestore() {
    final user = FirebaseAuth.instance.currentUser;

    debugPrint('🔍 AddSavingsPage initState: user = ${user?.uid}');

    if (user == null) {
      debugPrint('⚠️ User not authenticated in AddSavingsPage');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You must be signed in to add savings goals'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      });
      return;
    }

    savingsGoalsCol = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('savingsGoals');

    debugPrint('✅ AddSavingsPage Firestore path initialized: users/${user.uid}/savingsGoals');
  }

  void _initializeControllers() {
    _nameController = TextEditingController(
      text: widget.existingData != null
          ? widget.existingData!['name'] ?? ''
          : '',
    );

    _targetController = TextEditingController(
      text: widget.existingData != null
          ? widget.existingData!['targetAmount'].toString()
          : '',
    );

    _category = widget.existingData != null
        ? widget.existingData!['category'] ?? 'Emergency'
        : 'Emergency';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _saveSavingGoal() async {
    if (!_formKey.currentState!.validate()) return;

    final double targetAmount = double.tryParse(_targetController.text) ?? 0;
    final String name = _nameController.text;

    final data = {
      'name': name,
      'category': _category,
      'targetAmount': targetAmount,
      'currentAmount': widget.existingData?['currentAmount'] ?? 0.0,
      'createdAt': widget.existingData?['createdAt'] ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      if (widget.existingId != null) {
        await savingsGoalsCol.doc(widget.existingId).update(data);
        debugPrint('✅ Saving goal updated: ${widget.existingId}');
      } else {
        final docRef = await savingsGoalsCol.add(data);
        debugPrint('✅ Saving goal created: ${docRef.id}');
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              widget.existingId != null ? 'Savings goal updated' : 'Savings goal created'),
        ),
      );
      
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('❌ Error saving goal: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3C79C1), Color(0xFF2A466F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
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
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
             ),
                  const SizedBox(width: 10),
                  Text(
                    widget.existingId != null ? 'Edit Savings Goal' : 'Create Savings Goal',
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
                        Text('Goal Name', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        _buildTextField(
                          controller: _nameController,
                          hintText: 'e.g. Wedding Fund',
                          keyboardType: TextInputType.text,
                          prefixIcon: const Icon(Icons.label),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter goal name';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
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
                              hintText: 'e.g. Emergency, Travel',
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
                        Text('Target Amount (RM)', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                        const SizedBox(height: 4),
                        _buildTextField(
                          controller: _targetController,
                          hintText: '0.00',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          prefixIcon: const Icon(Icons.flag),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter target amount';
                            if (double.tryParse(value) == null) return 'Enter valid number';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        _buildGradientButton(
                          text: widget.existingId != null ? 'UPDATE GOAL' : 'CREATE GOAL',
                          onPressed: _saveSavingGoal,
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