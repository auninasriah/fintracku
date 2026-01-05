import 'package:flutter/material.dart';

const Color brandStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color brandEnd = Color(0xFF3F2A61); // Vibrant Purple

class OnPageSettings extends StatefulWidget {
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
  State<OnPageSettings> createState() => _OnPageSettingsState();
}

class _OnPageSettingsState extends State<OnPageSettings> with TickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _contentSlide;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _contentSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    _slideController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF3C79C1),
            Color.fromARGB(255, 129, 90, 193),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: SlideTransition(
            position: _contentSlide,
            child: FadeTransition(
              opacity: _slideController,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  /// Title
                  const Text(
                    "Customize your\nexperience",
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: Color.fromARGB(255, 255, 255, 255),
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    "Choose your preferences",
                    style: TextStyle(
                      fontSize: 14,
                      color: const Color.fromARGB(255, 255, 255, 255),
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 32),

                  /// Notifications Setting
                  _settingCard(
                    icon: Icons.notifications_rounded,
                    title: "Push Notifications",
                    description: "Get alerts for important updates",
                    isToggle: true,
                    value: widget.notifications,
                    onChanged: (value) => widget.onToggleNotifications(value),
                  ),

                  const SizedBox(height: 18),

                  /// Features Section
                  const Text(
                    "Available Features",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),
                  const SizedBox(height: 12),

                  _featureItem(
                    icon: Icons.bar_chart_rounded,
                    title: "Detailed Reports",
                    description: "Get comprehensive spending insights",
                  ),
                  const SizedBox(height: 12),

                  _featureItem(
                    icon: Icons.savings_rounded,
                    title: "Savings Goals",
                    description: "Track progress towards your targets",
                  ),
                  const SizedBox(height: 12),

                  _featureItem(
                    icon: Icons.trending_up_rounded,
                    title: "Investment Tracking",
                    description: "Monitor your portfolio growth",
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Setting Card with Toggle
  Widget _settingCard({
    required IconData icon,
    required String title,
    required String description,
    required bool isToggle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [brandStart, brandEnd],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Transform.scale(
            scale: 0.85,
            child: Switch(
              value: value,
              onChanged: onChanged,
              activeColor: brandStart,
            ),
          ),
        ],
      ),
    );
  }

  /// Theme Option
  Widget _themeOption({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 280),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? brandStart.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? brandStart : const Color(0xFFE8E8E8),
            width: isSelected ? 2 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: brandStart.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: isSelected ? brandStart : Colors.grey),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? brandStart : const Color(0xFF666666),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// Feature Item
  Widget _featureItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: brandStart.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: brandStart, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.check_circle_rounded, color: brandStart, size: 18),
        ],
      ),
    );
  }
}
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

