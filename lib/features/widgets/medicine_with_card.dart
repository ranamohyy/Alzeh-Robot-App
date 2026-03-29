// lib/features/widgets/medicine_with_card.dart - FIXED

import '../../core/resources/barallel.dart';

class MedicineWithDate extends StatelessWidget {
  const MedicineWithDate({
    super.key,
    required this.time,
    required this.date,
  });

  final String time;
  final String date;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              '$time    $date',
              style: TextStyle(color: Colors.white, fontSize: 12.sp),
            ),
          ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Icon(Icons.camera_alt, color: Colors.white, size: 30.r),
        ),
      ],
    );
  }
}