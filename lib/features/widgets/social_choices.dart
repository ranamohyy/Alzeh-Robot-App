import 'package:alzeh/core/resources/barallel.dart';

class SocialChoices extends StatelessWidget {
  const SocialChoices({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _socialButton(AppStrings.google, Colors.red),
        const SizedBox(width: 16),
        _socialButton(AppStrings.fb, Colors.blue[800]!),
        const SizedBox(width: 16),
        _socialButton(AppStrings.apple, Colors.black),
      ],
    );
  }

  Widget _socialButton(
    String icon,
    Color color,
  ) {
    return SizedBox(
        width: 25.w,
        height: 25.h,
        child: AppImage.svgImage(
          icon,
        ));
  }
}
