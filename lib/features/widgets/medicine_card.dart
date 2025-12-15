import 'package:alzeh/core/resources/barallel.dart';

class MedicineCard extends StatelessWidget {
  const MedicineCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primaryColor),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        spacing: 10,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          rowtextIcon('Medicine name', AppStrings.pillOutline),
          rowtextIcon('12:00 PM', AppStrings.time),
          rowtextIcon('Every 8 hours', AppStrings.shuffle),
          rowtextIcon('2 pills per a time', AppStrings.quantinty),
          Expanded(
            child: Center(
              child: InkWell(
                onTap: () {},
                child: Text('edit',
                    style: TextStyle(
                        decoration: TextDecoration.underline, fontSize: 16.sp)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget rowtextIcon(String text, String icon) {
  return Row(
    children: [
      AppImage.svgImage(
          icon,
          ColorFilter.mode(
            AppColors.primaryColor,
            BlendMode.srcIn,
          )),
      WidthSpace(8),
      Expanded(
        child: Text(
          text,
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
      ),
    ],
  );
}
