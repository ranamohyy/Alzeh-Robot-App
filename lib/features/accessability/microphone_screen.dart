// lib/features/accessability/microphone_screen.dart - FIXED

import 'dart:async'; // ADDED THIS IMPORT
import 'dart:io';
import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/audio_recording_service.dart';
import 'package:alzeh/features/widgets/record_button.dart';

class MicrophoneScreen extends StatefulWidget {
  const MicrophoneScreen({super.key});

  @override
  State<MicrophoneScreen> createState() => _MicrophoneScreenState();
}

class _MicrophoneScreenState extends State<MicrophoneScreen> {
  bool isRecording = false;
  bool isUploading = false;
  String recordingTime = '00:00:00';
  File? lastRecording;

  int _seconds = 0;
  Timer? _timer; // NOW Timer is defined

  @override
  void initState() {
    super.initState();
    _initializeRecorder();
  }

  Future<void> _initializeRecorder() async {
    await AudioRecordingService.initialize();
  }

  void _startTimer() {
    _seconds = 0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _seconds++;
        final hours = (_seconds ~/ 3600).toString().padLeft(2, '0');
        final minutes = ((_seconds % 3600) ~/ 60).toString().padLeft(2, '0');
        final secs = (_seconds % 60).toString().padLeft(2, '0');
        recordingTime = '$hours:$minutes:$secs';
      });
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _startRecording() async {
    final success = await AudioRecordingService.startRecording();
    if (success) {
      setState(() {
        isRecording = true;
      });
      _startTimer();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Failed to start recording'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _stopRecording() async {
    _stopTimer();

    final file = await AudioRecordingService.stopRecording();

    setState(() {
      isRecording = false;
      lastRecording = file;
    });

    if (file != null) {
      _showUploadDialog(file);
    }
  }

  Future<void> _showUploadDialog(File audioFile) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📤 Upload Recording'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send this recording to ESP32 Audio Player?'),
            HeightSpace(16),
            Text(
              'Duration: $recordingTime',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            HeightSpace(8),
            FutureBuilder<int>(
              future: audioFile.length(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final kb = (snapshot.data! / 1024).toStringAsFixed(1);
                  return Text('Size: $kb KB');
                }
                return const Text('Size: Calculating...');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
            ),
            child: const Text(
              'Upload',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (result == true) {
      await _uploadRecording(audioFile);
    }
  }

  Future<void> _uploadRecording(File audioFile) async {
    setState(() {
      isUploading = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            HeightSpace(16),
            const Text('Uploading to ESP32...'),
          ],
        ),
      ),
    );

    final success = await AudioRecordingService.uploadToESP32(audioFile);

    if (mounted) {
      Navigator.pop(context);

      setState(() {
        isUploading = false;
      });

      if (success) {
        await showSuccessDialog(
          context,
          '✓ Recording Uploaded!\n\nYou can now play it on ESP32',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Upload failed. Check ESP32 connection.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        appBarTiltle: 'Voice Recording',
      ),
      body: Column(
        children: [
          if (!isRecording && !isUploading)
            Padding(
              padding: EdgeInsets.all(16.r),
              child: Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    WidthSpace(12),
                    Expanded(
                      child: Text(
                        'Record voice message and upload to ESP32 Audio Player',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Expanded(
            child: isRecording
                ? StartRecordingScreen(
              recordingTime: recordingTime,
              isRecording: isRecording,
            )
                : _buildRecordingsList(),
          ),

          if (!isUploading)
            RecordButton(
              isRecording: isRecording,
              onTapDown: (_) => _startRecording(),
              onTapUp: (_) => _stopRecording(),
            ),

          HeightSpace(20),
        ],
      ),
    );
  }

  Widget _buildRecordingsList() {
    return ListView(
      padding: EdgeInsets.all(20.r),
      children: [
        if (lastRecording != null)
          _buildRecordingCard(
            'Last Recording',
            recordingTime,
            lastRecording!,
          ),

        const RecordingCardItem('Sample 1', '12 Oct 2025', '01:33'),
        const RecordingCardItem('Sample 2', '12 Oct 2025', '02:15'),
      ],
    );
  }

  Widget _buildRecordingCard(String title, String duration, File file) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.green.shade300, width: 2),
        borderRadius: BorderRadius.circular(12.r),
        color: Colors.green.shade50,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              spacing: 8.h,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.mic, color: Colors.green.shade700, size: 20.r),
                    WidthSpace(8),
                    Expanded(
                      child: Text(
                        title,
                        style: AppStyles.kTextStyle14primary.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  'Duration: $duration',
                  style: AppStyles.kTextStyle16Grey,
                ),
              ],
            ),
          ),

          IconButton(
            onPressed: () => _uploadRecording(file),
            icon: const Icon(Icons.upload),
            color: AppColors.primaryColor,
            iconSize: 28.r,
          ),
        ],
      ),
    );
  }
}