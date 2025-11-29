import 'package:flutter/material.dart';

class OnPageSettings extends StatelessWidget {
  final bool notifications;
  final String theme;
  final Function(bool) onToggleNotifications;
  final Function(String) onThemeChange;

  const OnPageSettings({
    super.key,
    required this.notifications,
    required this.theme,
    required this.onToggleNotifications,
    required this.onThemeChange,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),

          // ---------- Title ----------
          const Text(
            "Time to customise\nyour interest",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Select preferences to personalise your experience",
            style: TextStyle(color: Colors.grey),
          ),

          const SizedBox(height: 30),

          // ---------- Interest Grid ----------
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            children: [
              _interestChip(
                icon: Icons.notifications_active_rounded,
                label: "Alerts",
                selected: notifications,
                onTap: () => onToggleNotifications(!notifications),
              ),
              _interestChip(
                icon: Icons.light_mode_rounded,
                label: "Light",
                selected: theme == "light",
                onTap: () => onThemeChange("light"),
              ),
              _interestChip(
                icon: Icons.dark_mode_rounded,
                label: "Dark",
                selected: theme == "dark",
                onTap: () => onThemeChange("dark"),
              ),
              _interestChip(
                icon: Icons.bar_chart_rounded,
                label: "Reports",
                selected: true,
                onTap: () {},
              ),
              _interestChip(
                icon: Icons.savings_rounded,
                label: "Savings",
                selected: true,
                onTap: () {},
              ),
              _interestChip(
                icon: Icons.trending_up_rounded,
                label: "Tracking",
                selected: true,
                onTap: () {},
              ),
            ],
          ),

          // IMPORTANT:
          // ❌ No Save / Continue button here
          // ✅ Onboarding page already controls navigation
        ],
      ),
    );
  }

  // ---------- Interest Item ----------
  Widget _interestChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selected
              ? Colors.blueAccent.withOpacity(0.15)
              : Colors.grey.shade100,
          border: Border.all(
            color: selected ? Colors.blueAccent : Colors.transparent,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor:
                  selected ? Colors.blueAccent : Colors.grey.shade300,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.blueAccent : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
