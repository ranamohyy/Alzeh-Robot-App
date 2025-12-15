import 'package:alzeh/core/resources/barallel.dart';

// ignore: must_be_immutable
class RecordButton extends StatelessWidget {
  RecordButton(
      {super.key, required this.isRecording, this.onTapUp, this.onTapDown});
  bool isRecording;
  final Function(TapUpDetails)? onTapUp;
  final Function(TapDownDetails)? onTapDown;

  @override
  Widget build(BuildContext context) {
    return Column(
      spacing: 20.h,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(isRecording ? 'Recording...' : 'Hold to Record',
            style: AppStyles.kTextStyle18Primary.copyWith(
              color: Colors.red,
            )),
        GestureDetector(
          onTapDown: onTapDown,
          onTapUp: onTapUp,
          child: Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.red, width: 3.w),
            ),
            child: Center(
              child: Icon(
                Icons.mic,
                color: Colors.red,
                size: 40.r,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
