import 'package:alzeh/core/resources/app_utils.dart';
import 'package:alzeh/core/resources/barallel.dart';

class CheckMedicineCard extends StatelessWidget {
  const CheckMedicineCard({super.key, required this.status});
  final Status status;
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Container(
        padding: EdgeInsets.all(10.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16.r),
          color: AppColors.primaryColor,
        ),
        child: Column(
          spacing: 20.h,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HeightSpace(10),
            Row(
              children: [
                AppImage.svgImage(
                  AppStrings.pillOutline,
                ),
                WidthSpace(8),
                Expanded(
                  child:
                      Text('Medicine name', style: AppStyles.kTextStyle16white),
                ),
              ],
            ),
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.white, size: 20.r),
                WidthSpace(4),
                Text(
                  '12:00 PM',
                  style: TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
      Positioned(
        top: 2.h,
        right: 2.w,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: 8.w,
              vertical:
                  2.h), // EdgeInsets.symmetric(horizontal: 8, vertical: 4).r,
          decoration: BoxDecoration(
            color: bgColor(status),
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(16.r),
                bottomLeft: Radius.circular(16.r)),
          ),
          child: Row(
            spacing: 4.w,
            children: [
              getIcon(status),
              Text(
                status.name,
                style: TextStyle(
                  color: textColor(status),
                ),
              ),
            ],
          ),
        ),
      ),
    ]);
  }
}
