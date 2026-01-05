import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CreateAccountPage extends StatefulWidget {
  const CreateAccountPage({super.key});

  @override
  State<CreateAccountPage> createState() => _CreateAccountPageState();
}

class _CreateAccountPageState extends State<CreateAccountPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );
    
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError("Passwords do not match.");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final UserCredential userCred =
          await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = userCred.user!.uid;

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        
      });

      if (!mounted) return;

      Navigator.pushReplacementNamed(context, '/login');
    } on FirebaseAuthException catch (e, st) {
      debugPrint('FirebaseAuthException in _createAccount: $e');
      debugPrintStack(stackTrace: st);
      _showError(e.message ?? "Something went wrong.");
    } catch (e, st) {
      debugPrint('Unexpected error in _createAccount: $e');
      debugPrintStack(stackTrace: st);

      if (mounted) {
        await showDialog<void>(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Unexpected error'),
            content: SingleChildScrollView(
              child: Text(
                'Error: $e\n\nFull stack trace printed to console.\n\n'
                'If this mentions Pigeon or platform channels, run flutter clean and rebuild the app.',
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK')),
            ],
          ),
        );
      }

      _showError("Unexpected error: $e");
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color cardGradientStart = Color(0xFF3C79C1); // Vibrant Light Blue
    const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const SizedBox(height: 40),

              /// Application Logo - Fade Animation
              FadeTransition(
                opacity: _fadeAnimation,
                child: Image.asset(
                  'assets/images/myapp.png',
                  height: 80,
                  width: 80,
                ),
              ),
              const SizedBox(height: 20),

              /// Title - Slide Animation
              SlideTransition(
                position: _slideAnimation,
                child: Text(
                  "Create Account",
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: cardGradientStart,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              /// Subtitle - Slide Animation
              SlideTransition(
                position: _slideAnimation,
                child: Text(
                  "Register to get started",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              /// White Card Container - Slide Animation
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [

                      /// Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: "Name",
                          filled: true,
                          fillColor: const Color(0xFFF4F7FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty ? "Enter your name" : null,
                      ),
                      const SizedBox(height: 20),

                      /// Email
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: "Email",
                          filled: true,
                          fillColor: const Color(0xFFF4F7FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) =>
                            value == null || value.isEmpty
                                ? "Enter your email"
                                : null,
                      ),
                      const SizedBox(height: 15),

                      /// Password
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: "Password",
                          filled: true,
                          fillColor: const Color(0xFFF4F7FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        obscureText: true,
                        validator: (value) =>
                            value == null || value.length < 6
                                ? "Password must be at least 6 characters"
                                : null,
                      ),
                      const SizedBox(height: 15),

                      /// Confirm Password
                      TextFormField(
                        controller: _confirmPasswordController,
                        decoration: InputDecoration(
                          labelText: "Confirm Password",
                          filled: true,
                          fillColor: const Color(0xFFF4F7FF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        obscureText: true,
                        validator: (value) =>
                            value == null || value.isEmpty
                                ? "Confirm your password"
                                : null,
                      ),

                      const SizedBox(height: 35),

                      /// Create Account Button (Gradient)
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF3C79C1), // Vibrant Light Blue
                                Color.fromARGB(255, 125, 86, 187), // Vibrant Purple
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3C79C1).withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 6),
                              )
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _createAccount,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text(
                                    "Create Account",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 22),

                      /// Already have account? Login
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pushReplacementNamed(
                              context, '/login'),
                          child: RichText(
                            text: const TextSpan(
                              text: "Already have an account? ",
                              style: TextStyle(
                                color: Color(0xFF6C757D),
                                fontSize: 14,
                              ),
                              children: [
                                TextSpan(
                                  text: "Login",
                                  style: TextStyle(
                                    color: Color(0xFF3C79C1),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
