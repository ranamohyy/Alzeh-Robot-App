import '../../core/resources/barallel.dart';

class TodaysDosesSection extends StatelessWidget {
  const TodaysDosesSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text("Today's Doses", style: AppStyles.kTextStyle16Black),
      Text(
        'Manage',
        style: TextStyle(
          decoration: TextDecoration.underline,
          color: AppColors.primaryColor,
        ),
      ),
    ]);
  }
}
