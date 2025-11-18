// onboarding_screens/on_page_intro.dart

import 'package:flutter/material.dart';
import '../../onboarding_page.dart'; // Import for color definitions

class OnPageIntro extends StatelessWidget {
  const OnPageIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Align(
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/opening.png',
              height: 350, 
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(height: 40),

          // SHINING NEON TEXT 
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return const LinearGradient(
                colors: [neonTextStart, neonTextEnd], 
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ).createShader(bounds);
            },
            child: const Text( 
              "Welcome to FinTrackU",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 34, 
                fontWeight: FontWeight.w900,
                color: Colors.white, 
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 15),

          // BOLDER SUBTITLE 
          const Text(
            "Manage your money smarter and achieve your financial goals effortlessly!",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: accentPrimary, 
              height: 1.6, 
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}