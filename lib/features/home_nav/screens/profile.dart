// lib/features/home_nav/screens/profile.dart

import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/auth_service.dart';
import 'package:alzeh/features/auth/login.dart';
import 'package:alzeh/features/edit_profile/edit_profile.dart';
import 'package:alzeh/features/widgets/menu_items.dart';
import 'package:alzeh/features/widgets/person_data.dart';
import 'package:alzeh/features/widgets/profile_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Sign out
      await AuthService.signOut();

      // Close loading and navigate to login
      if (context.mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.all(16.r),
        child: Column(
          spacing: 16.h,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Profile', style: AppStyles.kTextStyle32primary),
            Row(
              children: [
                ProfileImage(),
                WidthSpace(16),
                PersonData(),
                Spacer(),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditProfileScreen(),
                      ),
                    );
                  },
                  child: AppImage.svgImage(AppStrings.edit),
                ),
              ],
            ),
            MenuItems(
              icon: AppStrings.settings,
              title: 'Settings',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Settings coming soon!')),
                );
              },
            ),
            MenuItems(
              icon: AppStrings.about,
              title: 'About Us',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('About Us coming soon!')),
                );
              },
            ),
            MenuItems(
              icon: AppStrings.share,
              title: 'Share The App',
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Share feature coming soon!')),
                );
              },
            ),
            MenuItems(
              icon: AppStrings.logOut,
              title: 'Log out',
              onTap: () => _logout(context),
              isRed: true,
            ),
          ],
        ),
      ),
    );
  }
}