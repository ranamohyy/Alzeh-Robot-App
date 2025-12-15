import 'package:alzeh/features/widgets/profile_image.dart';

import '../../core/resources/barallel.dart';

class PhotoAndSearch extends StatelessWidget {
  const PhotoAndSearch({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      spacing: 12.w,
      children: [
        ProfileImage(),
        Spacer(),
        AppImage.svgImage(AppStrings.search),
        AppImage.svgImage(AppStrings.notifications),
      ],
    );
  }
}
