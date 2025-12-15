import 'package:alzeh/core/resources/barallel.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    UserModel user = UserModel();
    return GestureDetector(
      onTap: () => closeKeyboard(context),
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        appBar: CustomAppBar(
          appBarTiltle: 'Edit Profile',
          showBackButton: true,
          centerTitile: false,
          titleStyle: AppStyles.kTextStyle18Primary,
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w),
            child: Column(
              spacing: 20.h,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChangeProfileImage(),
                LabelField('Name', user.name),
                LabelField('Email', user.email),
                LabelField('Mobile Number', user.phoneNumber),
                // Spacer(),
                HeightSpace(MediaQuery.of(context).size.height * 0.3),
                AppButton(hintText: 'Save And Continue')
              ],
            ),
          ),
        ),
      ),
    );
  }
}
