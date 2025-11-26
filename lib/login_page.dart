// login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';


const Color darkStart = Color(0xFF005CFF);
const Color darkEnd = Color(0xFF00FFC0);
const Color accentPrimary = Colors.white;
const Color actionGradientStart = Color(0xFF00E0FF);
const Color actionGradientEnd = Color(0xFF6A00FF);
const Color cardBackground = Color(0xCCFFFFFF);
const Color cardOverlay = Color(0x66FFFFFF);
const Color cardBorder = Color(0xFF00BFFF);
const Color errorRed = Color(0xFFB00020);

class LoginPage extends StatefulWidget {
  final Map<String, dynamic>? initialOnboardingData;
  const LoginPage({super.key, this.initialOnboardingData});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  late final AnimationController _animController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _slideAnim = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);

    // play entrance animation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _animController.forward());
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedEmail() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    final savedEmail = prefs.getString('saved_email');
    final remember = prefs.getBool('remember_email') ?? true;

    if (savedEmail != null) {
      _emailController.text = savedEmail;
    }

    setState(() {
      _rememberMe = remember;
    });
  }

  Future<void> _saveEmailPreference(String email, bool remember) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    if (remember) {
      await prefs.setString('saved_email', email);
      await prefs.setBool('remember_email', true);
    } else {
      await prefs.remove('saved_email');
      await prefs.setBool('remember_email', false);
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    FocusScope.of(context).unfocus();

    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();

    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      await _saveEmailPreference(email, _rememberMe);

      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed('/home');

    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "Login failed.");
    } catch (e) {
      _showError("An unexpected error occurred.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: errorRed),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600),
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white.withAlpha(235),
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black54),
        prefixIcon: Icon(icon, color: actionGradientStart),
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: cardBorder.withAlpha(115), width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: actionGradientStart.withAlpha(230), width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorRed, width: 1.6),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final bottomHeight = height * 0.52; // slightly more than half to fit comfortably

    return Scaffold(
      body: Stack(
        children: [
          // Background gradient and top content
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [darkStart, darkEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(height: 12),
                    Text("Welcome Back!",
                        style: TextStyle(color: accentPrimary, fontSize: 34, fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text("Log in to continue managing your finances",
                        style: TextStyle(color: Colors.white70, fontSize: 15)),
                  ],
                ),
              ),
            ),
          ),

          // Animated bottom container (slide + fade)
          Align(
            alignment: Alignment.bottomCenter,
            child: SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _fadeAnim,
                child: Container(
                  height: bottomHeight,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      topRight: Radius.circular(28),
                    ),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withAlpha(25), blurRadius: 20, offset: const Offset(0, -8)),
                    ],
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // drag indicator + optional small header
                      Center(
                        child: Container(
                          width: 48,
                          height: 4,
                          decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _buildTextField(
                                  controller: _emailController,
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || !v.contains("@")) return 'Enter a valid email.';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                _buildTextField(
                                  controller: _passwordController,
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  obscureText: _obscurePassword,
                                  suffixIcon: IconButton(
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.length < 6) return 'Minimum 6 characters.';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Checkbox(
                                      value: _rememberMe,
                                      activeColor: actionGradientStart,
                                      onChanged: (val) => setState(() => _rememberMe = val ?? true),
                                    ),
                                    const SizedBox(width: 8),
                                    const Text("Remember my email"),
                                    const Spacer(),
                                    TextButton(
                                      onPressed: () {
                          
                                      },
                                      child: const Text("Forgot?", style: TextStyle(color: Colors.black54)),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),

                                // Login Button
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton(
                                    onPressed: _isLoading ? null : _login,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      elevation: 6,
                                    ),
                                    child: Ink(
                                      decoration: const BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [actionGradientStart, actionGradientEnd],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                      ),
                                      child: Container(
                                        alignment: Alignment.center,
                                        height: 46,
                                        child: _isLoading
                                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: accentPrimary, strokeWidth: 2.5))
                                            : const Text('Log In', style: TextStyle(color: accentPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                                      ),
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Create account / alternative action
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Text("Don't have an account?"),
                                    TextButton(
                                      onPressed: () {
                                       Navigator.pushNamed(context, '/create-account');

                                      },
                                      child: const Text('Create one', style: TextStyle(color: actionGradientStart, fontWeight: FontWeight.bold)),
                                    ),
                                  ],
                                ),
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
          ),
        ],
      ),
    );
  }
}