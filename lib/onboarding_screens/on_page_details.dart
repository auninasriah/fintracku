import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
// Menggunakan import path yang anda berikan. Jika anda memindahkannya, mungkin perlu tukar kepada '../onboarding_page.dart'
import '../../onboarding_page.dart'; 

// DEFINISI FUNGSI UTILITY TYPE UNTUK KEGUNAAN BUILDER
typedef VibrantCardTextFieldBuilder = Widget Function({
  required TextEditingController controller,
  required String label,
  required IconData icon,
  TextInputType keyboardType,
});

class OnPageDetails extends StatelessWidget {
  final TextEditingController nameController;
  final TextEditingController ageController;
  final TextEditingController occupationController;
  // HANYA SATU PENGISYTIHARAN UNTUK FUNGSI BUILDER
  final VibrantCardTextFieldBuilder buildVibrantCardTextField; 

  const OnPageDetails({
    super.key,
    required this.nameController,
    required this.ageController,
    required this.occupationController,
    required this.buildVibrantCardTextField,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center, // Pusatkan kandungan
        children: [
          const SizedBox(height: 50),
          // ILLUSTRATION AREA
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(25),
                decoration: BoxDecoration(
                  color: cardBackground, 
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: cardShadowColor, 
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  LucideIcons.userPlus,
                  size: 80,
                  color: cardIconColor, 
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Personal Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: accentPrimary, 
                ),
              ),
               const SizedBox(height: 10),
               const Text(
                'This helps us tailor your financial journey.',
                style: TextStyle(
                  color: accentSecondary,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 50),
          
          // INPUT FIELDS
          buildVibrantCardTextField(
            controller: nameController,
            label: 'Your Full Name',
            icon: LucideIcons.user,
          ),
          const SizedBox(height: 20),
          buildVibrantCardTextField(
            controller: ageController,
            label: 'Age',
            icon: LucideIcons.cake,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 20),
          buildVibrantCardTextField(
            controller: occupationController,
            label: 'Occupation / Course',
            icon: LucideIcons.briefcase,
          ),
          const SizedBox(height: 50),
        ],
      ),
    );
  }
}