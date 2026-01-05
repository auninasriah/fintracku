import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';

// --- COLOR DEFINITIONS (Vibrant Blue & Purple Theme) ---
const Color cardGradientStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple

/// ProfileAvatar Widget
/// Displays the user's profile picture if saved, otherwise shows a default avatar
/// This widget automatically loads the saved image path from SharedPreferences
class ProfileAvatar extends StatefulWidget {
  final double radius;
  final VoidCallback? onTap; // Callback when avatar is tapped
  final bool showEditIcon; // Show edit icon overlay

  const ProfileAvatar({
    super.key,
    this.radius = 24,
    this.onTap,
    this.showEditIcon = true,
  });

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  String? _profileImagePath;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
  }

  /// Load the saved profile image path from SharedPreferences
  Future<void> _loadProfileImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPath = prefs.getString('profile_image_path');

      if (mounted) {
        setState(() {
          _profileImagePath = savedPath;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading profile image: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          // Main Avatar
          CircleAvatar(
            radius: widget.radius,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: _profileImagePath != null && File(_profileImagePath!).existsSync()
                ? FileImage(File(_profileImagePath!)) as ImageProvider
                : null,
            child: _profileImagePath == null || !File(_profileImagePath!).existsSync()
                ? Icon(
                    Icons.person,
                    size: widget.radius * 1.2,
                    color: Colors.grey.shade600,
                  )
                : null,
          ),

          // Edit Icon (optional overlay)
          if (widget.showEditIcon)
            Container(
              decoration: const BoxDecoration(
                color: cardGradientStart, // Vibrant Light Blue
                shape: BoxShape.circle,
              ),
              padding: const EdgeInsets.all(4),
              child: const Icon(
                Icons.camera_alt,
                size: 12,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
