// on_page_settings.dart

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../onboarding_page.dart'; // PASTI PATH BETUL

// DEFINISI FUNGSI UTILITY TYPE
typedef IllustrationAreaBuilder = Widget Function(IconData icon, String title);
typedef NotificationSetter = void Function(bool val);
typedef ThemeSetter = void Function(String val);

class OnPageSettings extends StatelessWidget {
  final bool notifications; // State
  final String theme; // State
  final NotificationSetter setNotifications; // Setter
  final ThemeSetter setTheme; // Setter
  final IllustrationAreaBuilder buildIllustrationArea; // Utility

  const OnPageSettings({
    super.key,
    required this.notifications,
    required this.theme,
    required this.setNotifications,
    required this.setTheme,
    required this.buildIllustrationArea,
  });

  // Widget untuk toggle setting
  Widget _buildToggleSetting(String title, bool value, void Function(bool) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: cardBorder, width: 1.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(color: cardTextPrimary, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: actionGradientStart, // Sky Blue
          ),
        ],
      ),
    );
  }

  // Widget untuk pilihan tema
  Widget _buildThemeOption(String title, String value, String currentValue, void Function(String) onChanged) {
    final selected = value == currentValue;
    return GestureDetector(
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: selected ? actionGradientStart : cardBackground, // Sky Blue/Card
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: selected ? actionGradientEnd : cardBorder, // Indigo/Card Border
            width: 2,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? accentPrimary : accentSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          buildIllustrationArea(LucideIcons.settings, 'Final Settings'),
          const SizedBox(height: 30),
          
          // Notifications Toggle
          const Text(
            'Notifications',
            style: TextStyle(
                color: accentPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildToggleSetting(
            'Enable Daily Notifications',
            notifications,
            setNotifications, // Panggil setter yang dihantar
          ),
          const SizedBox(height: 30),

          // Theme Selection
          const Text(
            'App Theme',
            style: TextStyle(
                color: accentPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildThemeOption(
                'Dark',
                'dark',
                theme,
                setTheme, // Panggil setter yang dihantar
              ),
              const SizedBox(width: 15),
              _buildThemeOption(
                'Light (Default)',
                'light',
                theme,
                setTheme, // Panggil setter yang dihantar
              ),
            ],
          ),
          const SizedBox(height: 50),
          const Text(
            'You can change these settings anytime later in the main app.',
            style: TextStyle(color: accentSecondary, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}