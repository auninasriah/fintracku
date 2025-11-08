import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const Color primaryDarkBlue = Color(0xFF1A3763);
  static const Color lightTextColor = Colors.white;

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: primaryDarkBlue,
      body: Center(
        child: Text(
          'App Settings',
          style: TextStyle(fontSize: 24, color: lightTextColor),
        ),
      ),
    );
  }
}
