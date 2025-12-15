import 'package:alzeh/core/resources/barallel.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar(
      {super.key,
      this.showBackButton = true,
      this.centerTitile = true,
      this.titleStyle,
      required this.appBarTiltle});
  final bool showBackButton;
  final String appBarTiltle;
  final bool? centerTitile;
  final TextStyle? titleStyle;
  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgColor,
      elevation: 0,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios,
                color: AppColors.primaryColor,
              ),
              onPressed: () => Navigator.pop(context),
            )
          : SizedBox.shrink(),
      title: Text(
        appBarTiltle,
        style: titleStyle ?? AppStyles.kTextStyle32primary,
      ),
      centerTitle: centerTitile,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
