import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// SettingsCard - Reusable card for settings sections
/// 
/// Usage:
///   SettingsCard(
///     title: 'Account Settings',
///     children: [
///       SettingsTile(...),
///       SettingsTile(...),
///     ],
///   )
class SettingsCard extends StatelessWidget {
  final String title;           // Title of the section
  final List<Widget> children;  // Content inside the card

  const SettingsCard({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF3C79C1),  // Light blue
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          // Content
          ...children,
        ],
      ),
    );
  }
}

/// SettingsTile - Individual setting row
/// 
/// Usage:
///   SettingsTile(
///     label: 'Name',
///     value: 'John Doe',
///     onTap: () { },
///   )
class SettingsTile extends StatelessWidget {
  final String label;              // Label (e.g., "Name")
  final String value;              // Current value to display
  final VoidCallback? onTap;       // What happens when tapped
  final bool showArrow;            // Show > arrow

  const SettingsTile({
    super.key,
    required this.label,
    required this.value,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Left: Label
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            // Right: Arrow
            if (showArrow)
              Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}