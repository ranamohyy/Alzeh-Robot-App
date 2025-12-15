import '../../core/resources/barallel.dart';

class ProfileImage extends StatelessWidget {
  const ProfileImage({super.key, this.radius, this.image});
  final double? radius;
  final ImageProvider? image;
  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius ?? 40.r,
      backgroundImage: image ??
          AssetImage(
            AppStrings.person,
          ),

      // child: image == null ? AppImage.assetsImage(AppStrings.person) : null,
    );
  }
}
