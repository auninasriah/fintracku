// login_page.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home_page.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';

const Color darkStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color darkEnd = Color(0xFF3F2A61); // Vibrant Purple
const Color accentPrimary = Colors.white;
const Color actionGradientStart = Color(0xFF3C79C1);
const Color actionGradientEnd = Color(0xFF2A466F);
const Color cardBorder = Color(0xFF3C79C1);
const Color errorRed = Color(0xFFB00020);

class LoginPage extends StatefulWidget {
  final Map<String, dynamic>? initialOnboardingData;
  const LoginPage({super.key, this.initialOnboardingData});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = true;

  late final AnimationController _animController;
  late final AnimationController _staggerController;
  late final Animation<Offset> _slideAnim;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _emailSlideAnim;
  late final Animation<Offset> _passwordSlideAnim;
  late final Animation<Offset> _buttonSlideAnim;
  late final Animation<double> _emailFadeAnim;
  late final Animation<double> _passwordFadeAnim;
  late final Animation<double> _buttonFadeAnim;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();

    _animController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _staggerController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));

    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeInOut);

    // Staggered animations for form fields
    _emailSlideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );

    _passwordSlideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
      ),
    );

    _buttonSlideAnim = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _staggerController,
        curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
      ),
    );

    _emailFadeAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _passwordFadeAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.2, 0.6, curve: Curves.easeIn),
    );

    _buttonFadeAnim = CurvedAnimation(
      parent: _staggerController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeIn),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _animController.forward();
      _staggerController.forward();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _staggerController.dispose();
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

    debugPrint('Attempting signIn for: $email');
    try {
      final userCred = await _auth
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 15), onTimeout: () {
            throw TimeoutException('Firebase sign-in timed out');
          });

      debugPrint('✅ Sign-in succeeded: uid=${userCred.user?.uid}');

      final uid = userCred.user!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!userDoc.exists) {
        await FirebaseFirestore.instance.collection('users').doc(uid).set({
          'email': email,
          'name': 'Unnamed User',
          'createdAt': FieldValue.serverTimestamp(),
        });
        debugPrint("User Firestore doc was missing — created automatically.");
      }

      await _saveEmailPreference(email, _rememberMe);

      final current = FirebaseAuth.instance.currentUser;
      debugPrint('FirebaseAuth.currentUser = ${current?.uid}');

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainShell(), // Use MainShell directly, not HomePage
        ),
      );

    } on TimeoutException catch (e) {
      // catch timeout first
      debugPrint('⏱️ TIMEOUT: $e');
      _showError('Sign-in timed out. Check your network.');
    } on FirebaseAuthException catch (e) {
      // then catch Firebase-specific errors
      debugPrint('🔐 FirebaseAuthException: code=${e.code}, msg=${e.message}');
      _showError(e.message ?? 'Login failed');
    } catch (e, st) {
      // finally catch all other errors
      debugPrint('❌ Unexpected error: $e');
      debugPrintStack(stackTrace: st);
      _showError('An error occurred: ${e.toString()}');
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

  
  Widget _buildRoundedField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.04 * 255).round()),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscure,
        validator: validator,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            color: Color(0xFFB0B0B0),
            fontSize: 14,
          ),
          prefixIcon: Icon(icon, color: darkStart, size: 22),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE8E8E8), width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: darkStart, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: errorRed, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: errorRed, width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
          errorStyle: const TextStyle(
            color: errorRed,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  // -----------------------------------------
  // BUILD UI
  // -----------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [darkStart, darkEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SlideTransition(
          position: _slideAnim,
          child: FadeTransition(
            opacity: _fadeAnim,
            child: Center(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                          /// White Card Container - Centered
                          Container(
                            width: double.infinity,
                            constraints: const BoxConstraints(maxWidth: 400),
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 24,
                                  offset: const Offset(0, 12),
                                  spreadRadius: 2,
                                ),
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  /// Logo
                                  Image.asset(
                                    'assets/images/myapp.png',
                                    height: 80,
                                    width: 80,
                                  ),
                                  const SizedBox(height: 20),

                                  /// Title
                                  const Text(
                                    "Welcome",
                                    style: TextStyle(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w800,
                                      color: darkStart,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 8),

                                  /// Subtitle
                                  Text(
                                    "Login to your account",
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade500,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 32),

                                  /// Email Field - Staggered Slide Animation
                                  SlideTransition(
                                    position: _emailSlideAnim,
                                    child: FadeTransition(
                                      opacity: _emailFadeAnim,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Email",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildRoundedField(
                                            controller: _emailController,
                                            hint: "Enter your email",
                                            icon: Icons.email_outlined,
                                            keyboard: TextInputType.emailAddress,
                                            validator: (v) =>
                                                (v == null || !v.contains("@")) ? "Enter a valid email" : null,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),

                                  /// Password Field - Staggered Slide Animation
                                  SlideTransition(
                                    position: _passwordSlideAnim,
                                    child: FadeTransition(
                                      opacity: _passwordFadeAnim,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text(
                                            "Password",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Color(0xFF333333),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          _buildRoundedField(
                                            controller: _passwordController,
                                            hint: "Enter your password",
                                            icon: Icons.lock_outline,
                                            obscure: _obscurePassword,
                                            validator: (v) =>
                                                (v == null || v.length < 6) ? "At least 6 characters" : null,
                                            suffix: IconButton(
                                              icon: Icon(
                                                _obscurePassword
                                                    ? Icons.visibility_off_outlined
                                                    : Icons.visibility_outlined,
                                                color: darkStart,
                                                size: 20,
                                              ),
                                              onPressed: () {
                                                setState(() => _obscurePassword = !_obscurePassword);
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 16),

                                  /// Remember Me & Forgot Password
                                  Row(
                                    children: [
                                      Checkbox(
                                        value: _rememberMe,
                                        onChanged: (v) =>
                                            setState(() => _rememberMe = v ?? true),
                                        activeColor: darkStart,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Text(
                                          "Remember Me",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Color(0xFF666666),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {},
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          "Forgot Password?",
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: darkStart,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      )
                                    ],
                                  ),

                                  const SizedBox(height: 28),

                                  /// Login Button - Enhanced with strong gradient and shadow
                                  SlideTransition(
                                    position: _buttonSlideAnim,
                                    child: FadeTransition(
                                      opacity: _buttonFadeAnim,
                                      child: SizedBox(
                                        width: double.infinity,
                                        height: 56,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(16),
                                            gradient: const LinearGradient(
                                              colors: [darkStart, darkEnd],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: darkStart.withOpacity(0.4),
                                                blurRadius: 16,
                                                offset: const Offset(0, 8),
                                                spreadRadius: 1,
                                              ),
                                              BoxShadow(
                                                color: darkEnd.withOpacity(0.2),
                                                blurRadius: 8,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isLoading ? null : _login,
                                              borderRadius: BorderRadius.circular(16),
                                              child: Center(
                                                child: _isLoading
                                                    ? Row(
                                                        mainAxisAlignment: MainAxisAlignment.center,
                                                        children: [
                                                          const CircularProgressIndicator(
                                                            color: Colors.white,
                                                            strokeWidth: 2.5,
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Text(
                                                            "Logging in...",
                                                            style: TextStyle(
                                                              fontSize: 16,
                                                              fontWeight: FontWeight.w600,
                                                              color: Colors.white.withOpacity(0.9),
                                                            ),
                                                          ),
                                                        ],
                                                      )
                                                    : const Text(
                                                        "Login",
                                                        style: TextStyle(
                                                          fontSize: 14,
                                                          fontWeight: FontWeight.w700,
                                                          color: Colors.white,
                                                          letterSpacing: 0.5,
                                                        ),
                                                      ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),

                                  const SizedBox(height: 20),

                                  /// Sign Up Link
                                  RichText(
                                    text: TextSpan(
                                      text: "Don't have an account? ",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF666666),
                                        fontWeight: FontWeight.w500,
                                      ),
                                      children: [
                                        WidgetSpan(
                                          child: GestureDetector(
                                            onTap: () {
                                              Navigator.pushNamed(
                                                  context, '/create-account');
                                            },
                                            child: const Text(
                                              "Sign Up",
                                              style: TextStyle(
                                                fontSize: 14,
                                                color: darkStart,
                                                fontWeight: FontWeight.w700,
                                                decoration: TextDecoration.none,
                                              ),
                                            ),
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
