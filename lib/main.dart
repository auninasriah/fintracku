// main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart' as fb_opt;

import 'splash_page.dart';
import 'onboarding_page.dart';
import 'login_page.dart';
import 'create_account.dart';
import 'home_page.dart'; // contains MainShell

/// 🎨 Theme colors
const Color primaryBlue = Color(0xFF11355F);
const Color accentBlue = Color(0xFF234A78);
const Color softGray = Color(0xFFF2F2F4);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: fb_opt.DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint("✅ Firebase initialized successfully!");
  } catch (e) {
    debugPrint("❌ Firebase initialization failed: $e");
  }

  runApp(const FinTrackUApp());
}

class FinTrackUApp extends StatelessWidget {
  const FinTrackUApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FinTrackU',
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        primaryColor: primaryBlue,
        scaffoldBackgroundColor: softGray,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: primaryBlue,
          secondary: accentBlue,
        ),
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),

      /// 🕐 Start with Splash Page
      initialRoute: '/splash',

      /// 🧭 Named routes for navigation
      routes: {
      '/splash': (context) => const SplashPage(),
      '/onboarding': (context) => const OnboardingPage(),

      // LOGIN (dengan args)
      '/login': (context) => const LoginPage(),
      '/create-account': (context) => const CreateAccountPage(),
      '/home': (context) => const HomePage(),
    },


    );
  }
}
