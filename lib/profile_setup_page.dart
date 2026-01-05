import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:io';

// --- COLOR DEFINITIONS (Vibrant Blue & Purple Theme) ---
const Color cardGradientStart = Color(0xFF3C79C1); // Vibrant Light Blue
const Color cardGradientEnd = Color.fromARGB(255, 125, 86, 187); // Vibrant Purple

/// ProfileSetupPage
/// Allows users to select and save a profile picture from their device gallery
/// The selected image is saved locally and the path is stored in SharedPreferences
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({super.key});

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  File? _selectedImage;
  bool _isSaving = false;
  final ImagePicker _imagePicker = ImagePicker();

  /// Pick an image from the device gallery
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85, // Compress image to reduce file size
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image from gallery', style: GoogleFonts.inter())),
        );
      }
    }
  }

  /// Pick an image from camera
  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint('Error taking photo: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error taking photo', style: GoogleFonts.inter())),
        );
      }
    }
  }

  /// Save the selected image locally and store the path in SharedPreferences
  Future<void> _saveProfileImage() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select an image first', style: GoogleFonts.inter())),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final profileDir = Directory('${appDocDir.path}/profile_pictures');

      if (!await profileDir.exists()) {
        await profileDir.create(recursive: true);
      }

      final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final savedImagePath = '${profileDir.path}/$fileName';

      final savedImage = await _selectedImage!.copy(savedImagePath);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', savedImage.path);

      if (mounted) {
        setState(() => _isSaving = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Profile picture saved successfully!', style: GoogleFonts.inter()),
            duration: const Duration(seconds: 2),
          ),
        );

        // IMPORTANT: Return true to signal success
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context, true);  // ← Changed from pop(context) to pop(context, true)
          }
        });
      }
    } catch (e) {
      debugPrint('Error saving profile image: $e');
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving image: $e', style: GoogleFonts.inter())),
        );
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
              colors: [cardGradientStart, cardGradientEnd],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        title: Text('Profile Picture Setup', style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.white,
        )),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Preview Section
              Container(
                height: 280,
                width: 280,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.file(
                          _selectedImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.image_not_supported,
                            size: 80,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No image selected',
                            style: GoogleFonts.inter(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Choose a photo below',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 40),

              // Action Buttons
              Text(
                'Select a profile picture',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 20),

              // Gallery Button
              ElevatedButton.icon(
                onPressed: _pickImageFromGallery,
                icon: const Icon(Icons.photo_library),
                label: Text('Choose from Gallery', style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardGradientStart,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Camera Button
              ElevatedButton.icon(
                onPressed: _pickImageFromCamera,
                icon: const Icon(Icons.camera_alt),
                label: Text('Take a Photo', style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                )),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cardGradientEnd,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 28,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveProfileImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isSaving
                        ? Colors.grey.shade400
                        : cardGradientStart,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          'Save Profile Picture',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.grey),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    'Cancel',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
