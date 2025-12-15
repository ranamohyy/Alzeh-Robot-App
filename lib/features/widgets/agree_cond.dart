import '../../core/resources/barallel.dart';

class AgreeToConditions extends StatelessWidget {
  const AgreeToConditions({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: 'I agree to the ',
        style: AppStyles.kTextStyle16Grey.copyWith(fontSize: 14.sp),
        children: [
          TextSpan(
            text: 'terms&Conditions',
            style: AppStyles.kTextStyle14primary,
          ),
          TextSpan(
            text: ' and ',
            style: AppStyles.kTextStyle16Grey.copyWith(fontSize: 14.sp),
          ),
          TextSpan(
            text: 'Privacy Policy',
            style: AppStyles.kTextStyle14primary,
          ),
        ],
      ),
    );
  }
}
