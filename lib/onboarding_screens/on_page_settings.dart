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
      padding: const EdgeInsets.all(26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Notifications",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SwitchListTile(
            title: const Text("Enable daily notifications"),
            value: notifications,
            onChanged: onToggleNotifications,
          ),

          const SizedBox(height: 20),

          const Text(
            "Theme",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),

          Row(
            children: [
            _themeButton("light"),
            const SizedBox(width: 10),
            _themeButton("dark"),
          ],
         )
        ],
      ),
    );
  }

  Widget _themeButton(String t) {
    final bool isSelected = theme == t;
    return ChoiceChip(
      label: Text(t.toUpperCase()),
      selected: isSelected,
      onSelected: (_) => onThemeChange(t),
      selectedColor: Colors.blueAccent,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }
}
