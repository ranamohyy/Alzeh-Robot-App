import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/features/widgets/record_button.dart';

class MicrophoneScreen extends StatefulWidget {
  const MicrophoneScreen({super.key});

  @override
  State<MicrophoneScreen> createState() => _MicrophoneScreenState();
}

class _MicrophoneScreenState extends State<MicrophoneScreen> {
  bool isRecording = false;
  String recordingTime = '00 : 00 : 35';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        appBarTiltle: 'Microphone',
      ),
      body: Column(
        children: [
          Expanded(
            child: isRecording == true
                ? StartRecordingScreen(
                    recordingTime: recordingTime,
                    isRecording: isRecording,
                  )
                : _recordingsList(),
          ),
          RecordButton(
            isRecording: isRecording,
            onTapUp: (_) {
              setState(() => isRecording = false);
              showSuccessDialog(context, "Recording saved successfully");
            },
            onTapDown: (_) => setState(() => isRecording = true),
          ),
          HeightSpace(20)
        ],
      ),
    );
  }

  Widget _recordingsList() {
    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        RecordingCardItem('New Recording', '12 Oct 2025', '01:33'),
        RecordingCardItem('New Recording', '12 Oct 2025', '01:33'),
        RecordingCardItem('New Recording', '12 Oct 2025', '01:33'),
        RecordingCardItem('New Recording', '12 Oct 2025', '01:33'),
      ],
    );
  }
}
