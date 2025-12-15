import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/features/custom_paint/wave_form.dart';

class StartRecordingScreen extends StatelessWidget {
  StartRecordingScreen({
    super.key,
    required this.recordingTime,
    required this.isRecording,
  });

  final String recordingTime;
  bool isRecording;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(recordingTime,
              style: AppStyles.kTextStyle32primary.copyWith(color: Colors.red)),
          HeightSpace(40),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: CustomPaint(
              painter: WaveformPainter(),
              size: Size(double.infinity, 150.h),
            ),
          ),
          HeightSpace(40),
        ],
      ),
    );
  }
}
