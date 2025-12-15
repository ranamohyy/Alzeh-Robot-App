import '../../../core/resources/barallel.dart';

class PatiendDetails extends StatelessWidget {
  const PatiendDetails({super.key});
  @override
  Widget build(BuildContext context) {
    final UserModel user = UserModel();
    return GestureDetector(
      onTap: () => closeKeyboard(context),
      child: Scaffold(
        backgroundColor: AppColors.bgColor,
        body: SingleChildScrollView(
          padding: EdgeInsets.all(16.r),
          child: Column(
            spacing: 25.h,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HeightSpace(2),
              Text('Patient’s Details', style: AppStyles.kTextStyle32primary),
              LabelField('Name', user.name),
              LabelField('age', user.email),
              LabelField('Mobile Number', user.phoneNumber),
              LabelField('Disease', user.disease),
            ],
          ),
        ),
      ),
    );
  }
}
