import 'package:flutter/material.dart';

class OnPageIntro extends StatelessWidget {
  const OnPageIntro({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(26),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/opening.png',
            height: 260,
          ),
          const SizedBox(height: 40),
          const Text(
            "Welcome to FinTrackU",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            "Track income, set goals, and manage your financial journey easily.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, height: 1.4),
          ),
        ],
      ),
    );
  }
}
