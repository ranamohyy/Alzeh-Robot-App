// lib/features/medication/post_dispense_screen.dart
// AUTOMATIC SCREEN AFTER PILL DISPENSING

import 'dart:async';
import 'dart:typed_data';
import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/camera_service.dart';
import 'package:alzeh/core/services/audio_recording_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PostDispenseScreen extends StatefulWidget {
  const PostDispenseScreen({
    super.key,
    required this.medicationName,
    required this.pillsDispensed,
  });

  final String medicationName;
  final int pillsDispensed;

  @override
  State<PostDispenseScreen> createState() => _PostDispenseScreenState();
}

class _PostDispenseScreenState extends State<PostDispenseScreen> {
  // Camera state
  Timer? _snapshotTimer;
  Uint8List? _currentFrame;
  bool _isCameraActive = false;
  int _frameCount = 0;

  // Audio state
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  File? _lastRecording;

  // Auto-dismiss timer
  Timer? _autoDismissTimer;
  int _remainingSeconds = 30;

  @override
  void initState() {
    super.initState();
    _startCamera();
    _startAutoDismissTimer();
  }

  @override
  void dispose() {
    _stopCamera();
    _stopRecording();
    _autoDismissTimer?.cancel();
    _recordingTimer?.cancel();
    super.dispose();
  }

  // ==================== AUTO-DISMISS ====================

  void _startAutoDismissTimer() {
    _autoDismissTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _remainingSeconds--;
      });

      if (_remainingSeconds <= 0) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    _autoDismissTimer?.cancel();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  // ==================== CAMERA ====================

  Future<void> _startCamera() async {
    setState(() {
      _isCameraActive = true;
    });

    _snapshotTimer = Timer.periodic(
      const Duration(milliseconds: 300), // ~3 FPS
          (timer) async {
        await _fetchSnapshot();
      },
    );
  }

  void _stopCamera() {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    _currentFrame = null;
    _isCameraActive = false;
  }

  Future<void> _fetchSnapshot() async {
    if (!_isCameraActive) return;

    try {
      final snapshotUrl = '${CameraService.getStreamUrl().replaceAll('/stream', '/snapshot')}';

      final response = await http.get(Uri.parse(snapshotUrl)).timeout(
        const Duration(seconds: 2),
      );

      if (response.statusCode == 200 && mounted) {
        setState(() {
          _currentFrame = response.bodyBytes;
          _frameCount++;
        });
      }
    } catch (e) {
      // Silently fail - not critical
    }
  }

  Future<void> _capturePhoto() async {
    if (_currentFrame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No camera frame available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // TODO: Save photo with medication info
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Photo captured!'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  // ==================== AUDIO ====================

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    final success = await AudioRecordingService.startRecording();

    if (success) {
      setState(() {
        _isRecording = true;
        _recordingSeconds = 0;
      });

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
        });
      });
    }
  }

  Future<void> _stopRecording() async {
    _recordingTimer?.cancel();

    final file = await AudioRecordingService.stopRecording();

    setState(() {
      _isRecording = false;
      _lastRecording = file;
    });

    if (file != null) {
      _showUploadDialog(file);
    }
  }

  Future<void> _showUploadDialog(File audioFile) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('📤 Upload Voice Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Send this voice note to ESP32 Audio Player?'),
            HeightSpace(16),
            Text(
              'Duration: ${_formatDuration(_recordingSeconds)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
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

    final filename = '${widget.medicationName}_${DateTime.now().millisecondsSinceEpoch}.wav';
    final success = await AudioRecordingService.uploadToESP32(
      audioFile,
      customFilename: filename,
    );

    if (mounted) {
      Navigator.pop(context);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Voice note uploaded!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Upload failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  // ==================== UI ====================

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _stopRecording();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              // Main content
              Column(
                children: [
                  // Header
                  _buildHeader(),

                  // Camera feed
                  Expanded(
                    child: _buildCameraView(),
                  ),

                  // Controls
                  _buildControls(),
                ],
              ),

              // Auto-dismiss countdown
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    'Auto-close in ${_remainingSeconds}s',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(16.r),
      color: Colors.black87,
      child: Column(
        spacing: 8.h,
        children: [
          Row(
            children: [
              Icon(Icons.medication, color: Colors.green, size: 24.r),
              WidthSpace(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dispensed Successfully',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${widget.medicationName} (${widget.pillsDispensed} pills)',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12.sp,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _dismiss,
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ],
          ),
          Text(
            'Take a photo or record a voice note (optional)',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraView() {
    return Container(
      color: Colors.black,
      child: _currentFrame != null
          ? Stack(
        children: [
          Center(
            child: Image.memory(
              _currentFrame!,
              fit: BoxFit.contain,
              gaplessPlayback: true,
            ),
          ),
          if (_isCameraActive)
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(8.r),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8.w,
                      height: 8.h,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    WidthSpace(6),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      )
          : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.white),
            HeightSpace(16),
            Text(
              'Connecting to camera...',
              style: TextStyle(color: Colors.white70, fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.r),
          topRight: Radius.circular(20.r),
        ),
      ),
      child: Column(
        spacing: 16.h,
        children: [
          // Camera controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildControlButton(
                icon: Icons.camera_alt,
                label: 'Capture',
                onPressed: _capturePhoto,
                color: Colors.blue,
              ),
              _buildControlButton(
                icon: _isRecording ? Icons.stop : Icons.mic,
                label: _isRecording
                    ? _formatDuration(_recordingSeconds)
                    : 'Record',
                onPressed: _toggleRecording,
                color: _isRecording ? Colors.red : Colors.green,
                isActive: _isRecording,
              ),
              _buildControlButton(
                icon: Icons.check_circle,
                label: 'Done',
                onPressed: _dismiss,
                color: Colors.white,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
    bool isActive = false,
  }) {
    return Column(
      spacing: 8.h,
      children: [
        GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 60.w,
            height: 60.h,
            decoration: BoxDecoration(
              color: isActive ? color : color.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 2),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : color,
              size: 30.r,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 12.sp,
          ),
        ),
      ],
    );
  }
}