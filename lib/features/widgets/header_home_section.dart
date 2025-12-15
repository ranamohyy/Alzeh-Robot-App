import 'package:alzeh/features/widgets/photo_and_name.dart';

import '../../core/resources/barallel.dart';

class HeaderHomeSection extends StatelessWidget {
  const HeaderHomeSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 12.h,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PhotoAndSearch(),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Hello, Mohammed', style: AppStyles.kTextStyle22Primary),
          Text(
            '15 Dec 2025',
            style: AppStyles.kTextStyle14primary,
          ),
        ]),
      ],
    );
  }
}
