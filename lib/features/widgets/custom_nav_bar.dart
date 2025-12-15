import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import '../../core/resources/barallel.dart';

// ignore: must_be_immutable
class CustomNavBar extends StatefulWidget {
  CustomNavBar({super.key, required this.onTap, required this.currentIndex});
  final void Function(int)? onTap;
  int currentIndex;

  @override
  State<CustomNavBar> createState() => _CustomNavBarState();
}

class _CustomNavBarState extends State<CustomNavBar> {
  @override
  Widget build(BuildContext context) {
    int currentIndex = widget.currentIndex;
    return CurvedNavigationBar(
      backgroundColor: AppColors.bgColor,
      color: AppColors.primaryColor,
      index: currentIndex,
      items: [
        AppImage.svgImage(
          AppStrings.listItems,
        ),
        AppImage.svgImage(
          AppStrings.home,
        ),
        AppImage.svgImage(
          AppStrings.pill,
        ),
        AppImage.svgImage(AppStrings.settings,
            ColorFilter.mode(AppColors.whiteColor, BlendMode.srcIn)),
      ],
      onTap: widget.onTap,
    );
  }
}
