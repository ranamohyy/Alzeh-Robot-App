import 'package:alzeh/core/resources/barallel.dart';

class RecordingCardItem extends StatelessWidget {
  const RecordingCardItem(
    this.title,
    this.date,
    this.duration, {
    super.key,
  });

  final String title;
  final String date;
  final String duration;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: ()=>showSuccessDialog(context, "Record Sent successfully"),

      child: Container(
        margin: EdgeInsets.only(bottom: 12.h),
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              spacing: 8.h,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppStyles.kTextStyle14primary),
                Text(date, style: AppStyles.kTextStyle16Grey),
              ],
            ),
            Text(
              duration,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
