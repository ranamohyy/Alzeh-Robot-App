import 'package:alzeh/core/resources/barallel.dart';

class QuickAccessSection extends StatelessWidget {
  const QuickAccessSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: 20.h,
      children: [
        Text('Quick Access', style: AppStyles.kTextStyle18Primary),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _quickAccessButton(
              Icons.camera_alt,
              'Camera',
              context,
              CameraScreen(),
            ),
            _quickAccessButton(Icons.mic, 'Voice', context, MicrophoneScreen()),
            _quickAccessButton(Icons.edit, 'Manual', context, ManualChange()),
          ],
        ),
      ],
    );
  }
}

Widget _quickAccessButton(
    IconData icon, String label, BuildContext context, Widget routeScreen) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
          context, MaterialPageRoute(builder: (context) => routeScreen));
    },
    child: Column(
      spacing: 10.h,
      children: [
        Container(
          width: 70.w,
          height: 70.h,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 30.r),
        ),
        Text(label, style: AppStyles.kTextStyle14primary),
      ],
    ),
  );
}
