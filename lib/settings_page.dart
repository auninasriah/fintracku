import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'widgets/settings_card.dart';
import 'profile_setup_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // User info
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  String _userPhone = '';

  // App info
  String _appVersion = 'Loading...';
  String _buildNumber = 'Loading...';

  // Password field visibility
  bool _showCurrentPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmPassword = false;

  // Text controllers for password change
  late TextEditingController _currentPasswordController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();

    _loadUserData();
    _loadAppInfo();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Load user data from Firebase
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        setState(() {
          _userName = data['name'] ?? 'Not set';
          _userEmail = user.email ?? 'Not available';
          _userPhone = data['phone'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  /// Load app version and build info
  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;  // e.g., "1.0.0"
        _buildNumber = packageInfo.buildNumber;  // e.g., "1"
      });
    } catch (e) {
      debugPrint('Error loading app info: $e');
    }
  }

  /// Edit user name
  Future<void> _editName() async {
    final nameController = TextEditingController(text: _userName);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Name'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(hintText: 'Enter your name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                // Save to Firebase
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'name': nameController.text});

                    setState(() => _userName = nameController.text);
                  }
                } catch (e) {
                  debugPrint('Error updating name: $e');
                }

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Edit user phone
  Future<void> _editPhone() async {
    final phoneController = TextEditingController(text: _userPhone);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Phone Number'),
          content: TextField(
            controller: phoneController,
            decoration: const InputDecoration(hintText: 'Enter your phone number'),
            keyboardType: TextInputType.phone,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                try {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    await FirebaseFirestore.instance
                        .collection('users')
                        .doc(user.uid)
                        .update({'phone': phoneController.text});

                    setState(() => _userPhone = phoneController.text);
                  }
                } catch (e) {
                  debugPrint('Error updating phone: $e');
                }

                if (mounted) Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  /// Change password
  Future<void> _changePassword() async {
    // Validate inputs
    if (_currentPasswordController.text.isEmpty ||
        _newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Re-authenticate user with current password
      final credentials = EmailAuthProvider.credential(
        email: user.email!,
        password: _currentPasswordController.text,
      );

      await user.reauthenticateWithCredential(credentials);

      // Update password
      await user.updatePassword(_newPasswordController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Password changed successfully')),
        );

        // Clear fields
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.message}')),
        );
      }
    }
  }

  /// Logout user
  Future<void> _logout() async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      try {
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } catch (e) {
        debugPrint('Error logging out: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF3C79C1), Color.fromARGB(255, 125, 86, 187)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text(
          'Settings',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w700,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      backgroundColor: const Color(0xFFF6F7FB),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            // SECTION 1: Account Settings
            SettingsCard(
              title: 'ACCOUNT SETTINGS',
              children: [
                // Profile Picture Display
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3C79C1), Color.fromARGB(255, 125, 86, 187)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF3C79C1).withValues(alpha: 0.2),
                              blurRadius: 15,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _userName,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF3C79C1),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _userEmail,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
                const Divider(),
                // Profile Picture Edit
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileSetupPage()),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.camera_alt, color: Color(0xFF3C79C1)),
                        const SizedBox(width: 12),
                        Text(
                          'Edit Profile Picture',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
                      ],
                    ),
                  ),
                ),
                const Divider(),
                // Name
                SettingsTile(
                  label: 'Name',
                  value: _userName,
                  onTap: _editName,
                ),
                // Email (Display only)
                SettingsTile(
                  label: 'Email',
                  value: _userEmail,
                  onTap: null,  // Not editable
                  showArrow: false,
                ),
                // Phone
                SettingsTile(
                  label: 'Phone Number',
                  value: _userPhone.isEmpty ? 'Not set' : _userPhone,
                  onTap: _editPhone,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // SECTION 2: Change Password
            SettingsCard(
              title: ' CHANGE PASSWORD',
              children: [
                // Current Password
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Password',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _currentPasswordController,
                      obscureText: !_showCurrentPassword,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter current password',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3C79C1), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showCurrentPassword ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() => _showCurrentPassword = !_showCurrentPassword);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // New Password
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'New Password',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: !_showNewPassword,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Enter new password',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3C79C1), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showNewPassword ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() => _showNewPassword = !_showNewPassword);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Confirm Password
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm Password',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: !_showConfirmPassword,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Confirm new password',
                        hintStyle: GoogleFonts.inter(
                          fontSize: 13,
                          color: Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF3C79C1), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _showConfirmPassword ? Icons.visibility : Icons.visibility_off,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          onPressed: () {
                            setState(() => _showConfirmPassword = !_showConfirmPassword);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Save Button
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3C79C1).withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
                      )
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _changePassword,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF3C79C1), Color.fromARGB(255, 125, 86, 187)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Center(
                          child: Text(
                            'Update Password',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // SECTION 3: App Information
            SettingsCard(
              title: 'APP INFORMATION',
              children: [
                SettingsTile(
                  label: 'Version Number',
                  value: _appVersion,
                  showArrow: false,
                ),
                SettingsTile(
                  label: 'Build Number',
                  value: _buildNumber,
                  showArrow: false,
                ),
                SettingsTile(
                  label: 'Last Updated',
                  value: 'December 12, 2025',
                  showArrow: false,
                ),
              ],
            ),

            const SizedBox(height: 8),

            // SECTION 4: Logout
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  )
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _logout,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Logout',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}