import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/features/edit_profile/edit_profile.dart';
import 'package:alzeh/features/widgets/menu_items.dart';
import 'package:alzeh/features/widgets/person_data.dart';
import 'package:alzeh/features/widgets/profile_image.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                          builder: (context) => EditProfileScreen(),
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
                onTap: () {},
              ),
              MenuItems(
                icon: AppStrings.about,
                title: 'About Us',
                onTap: () {},
              ),
              MenuItems(
                icon: AppStrings.share,
                title: 'Share The App',
                onTap: () {},
              ),
              MenuItems(
                icon: AppStrings.logOut,
                title: 'Log out',
                onTap: () {},
                isRed: true,
              ),
            ]),
      ),
    );
  }
}
