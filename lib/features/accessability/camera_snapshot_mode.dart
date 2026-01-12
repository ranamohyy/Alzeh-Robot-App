// lib/features/accessability/camera_snapshot_mode.dart
// SNAPSHOT-BASED PSEUDO-STREAM (More reliable for mobile)

import 'dart:async';
import 'dart:typed_data';
import 'dart:io';
import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/camera_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class CameraScreenSnapshotMode extends StatefulWidget {
  const CameraScreenSnapshotMode({super.key});

  @override
  State<CameraScreenSnapshotMode> createState() => _CameraScreenSnapshotModeState();
}

class _CameraScreenSnapshotModeState extends State<CameraScreenSnapshotMode> {
  bool isMonitoring = false;
  bool isStreaming = false;
  List<CapturedPhoto> photos = [];

  // Snapshot mode state
  Timer? _snapshotTimer;
  Uint8List? _currentFrame;
  bool _isConnected = false;
  String _status = 'Not connected';
  int _frameCount = 0;
  int _failCount = 0;

  @override
  void dispose() {
    _stopSnapshotMode();
    super.dispose();
  }

  void _stopSnapshotMode() {
    _snapshotTimer?.cancel();
    _snapshotTimer = null;
    _currentFrame = null;
    _isConnected = false;
    _frameCount = 0;
    _failCount = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(appBarTiltle: 'Camera Monitoring'),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(20.r),
          child: Column(
            spacing: 20.h,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Info Banner
              Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.green.shade700),
                    WidthSpace(12),
                    Expanded(
                      child: Text(
                        'Snapshot mode: More stable for mobile\nESP32 IP: ${CameraService.esp32CameraIP}',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Start/Stop Button
              if (!isStreaming)
                ElevatedButton.icon(
                  onPressed: _startSnapshotMode,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Live View (Snapshots)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50.h),
                  ),
                ),

              // Live View Container
              if (isStreaming) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.black,
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(10.r),
                            topRight: Radius.circular(10.r),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 10.w,
                                  height: 10.h,
                                  decoration: BoxDecoration(
                                    color: _isConnected ? Colors.red : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                WidthSpace(8),
                                Text(
                                  _isConnected ? 'LIVE' : 'CONNECTING...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              '$_frameCount frames',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Image Display
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10.r),
                          bottomRight: Radius.circular(10.r),
                        ),
                        child: Container(
                          height: 300.h,
                          color: Colors.black,
                          child: _currentFrame != null
                              ? Image.memory(
                            _currentFrame!,
                            fit: BoxFit.contain,
                            gaplessPlayback: true,
                          )
                              : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                                HeightSpace(16),
                                Text(
                                  _status,
                                  style: TextStyle(color: Colors.white),
                                ),
                                if (_failCount > 0)
                                  Text(
                                    'Fails: $_failCount',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Controls
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _stopSnapshotMode();
                          setState(() {
                            isStreaming = false;
                            _status = 'Stopped';
                          });
                        },
                        icon: const Icon(Icons.stop, size: 18),
                        label: const Text('Stop'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    WidthSpace(8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _captureSnapshot,
                        icon: const Icon(Icons.camera_alt, size: 18),
                        label: const Text('Save'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Monitoring Controls
              ElevatedButton.icon(
                onPressed: isMonitoring ? _stopMonitoring : _startMonitoring,
                icon: Icon(isMonitoring ? Icons.stop : Icons.play_arrow),
                label: Text(
                  isMonitoring
                      ? 'Stop Auto Monitoring'
                      : 'Start Auto Monitoring (Motion Detection)',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMonitoring ? Colors.red : Colors.orange,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50.h),
                ),
              ),

              if (isMonitoring)
                Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.motion_photos_on, color: Colors.orange.shade700),
                      WidthSpace(12),
                      Expanded(
                        child: Text(
                          'Motion detection active - Images saved automatically',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Captured Photos
              Text(
                'Captured Photos',
                style: AppStyles.kTextStyle18Primary,
              ),

              ...photos.map((photo) => CameraPhotoCard(
                photo.time,
                photo.date,
                imageFile: photo.file,
                frameData: photo.frameData,
              )),

              if (photos.isEmpty)
                Container(
                  padding: EdgeInsets.all(32.r),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.photo_camera_outlined,
                        size: 64.r,
                        color: Colors.grey,
                      ),
                      HeightSpace(16),
                      Text(
                        'No photos yet',
                        style: AppStyles.kTextStyle16Grey,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // SNAPSHOT MODE: Fetch images repeatedly
  Future<void> _startSnapshotMode() async {
    setState(() {
      isStreaming = true;
      _status = 'Connecting...';
      _frameCount = 0;
      _failCount = 0;
    });

    print('📸 Starting snapshot mode');
    print('   URL: ${CameraService.getStreamUrl().replaceAll('/stream', '/snapshot')}');

    // Start periodic snapshot fetching
    _snapshotTimer = Timer.periodic(
      const Duration(milliseconds: 200), // 5 FPS
          (timer) async {
        await _fetchSnapshot();
      },
    );
  }

  Future<void> _fetchSnapshot() async {
    try {
      final snapshotUrl = '${CameraService.getStreamUrl().replaceAll('/stream', '/snapshot')}';

      final response = await http.get(Uri.parse(snapshotUrl)).timeout(
        const Duration(seconds: 2),
      );

      if (response.statusCode == 200) {
        _frameCount++;
        _failCount = 0;

        if (_frameCount == 1) {
          print('✅ First snapshot received! Size: ${response.bodyBytes.length} bytes');
        }

        if (!_isConnected) {
          print('✅ Snapshot mode connected successfully');
        }

        if (mounted) {
          setState(() {
            _currentFrame = response.bodyBytes;
            _isConnected = true;
            _status = 'Live ($_frameCount frames)';
          });
        }
      } else {
        _failCount++;
        print('⚠️  Snapshot failed: HTTP ${response.statusCode}');

        if (_failCount > 5 && mounted) {
          setState(() {
            _isConnected = false;
            _status = 'Connection issues';
          });
        }
      }
    } catch (e) {
      _failCount++;

      if (_failCount == 1) {
        print('❌ Snapshot error: $e');
      }

      if (_failCount > 10 && mounted) {
        setState(() {
          _isConnected = false;
          _status = 'Failed: $e';
        });
      }
    }
  }

  Future<void> _captureSnapshot() async {
    if (_currentFrame == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ No frame available'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    final now = DateTime.now();
    setState(() {
      photos.insert(
        0,
        CapturedPhoto(
          file: null,
          time: TimeOfDay.now().format(context),
          date: '${now.day}/${now.month}/${now.year}',
          note: 'Saved snapshot',
          frameData: _currentFrame,
        ),
      );
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Photo saved!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _startMonitoring() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            HeightSpace(16),
            const Text('Starting monitoring...'),
          ],
        ),
      ),
    );

    final success = await CameraService.startMonitoring(durationSeconds: 300);

    if (mounted) {
      Navigator.pop(context);

      if (success) {
        setState(() {
          isMonitoring = true;
          if (!isStreaming) {
            _startSnapshotMode();
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Monitoring started - 5 minutes'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Failed to start monitoring'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopMonitoring() async {
    final success = await CameraService.stopMonitoring();

    setState(() {
      isMonitoring = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(success ? '✓ Monitoring stopped' : '⚠️ Stop command sent'),
          backgroundColor: success ? Colors.green : Colors.orange,
        ),
      );
    }
  }
}

// Photo data classes (same as MJPEG version)
class CapturedPhoto {
  final File? file;
  final String time;
  final String date;
  final String? note;
  final Uint8List? frameData;

  CapturedPhoto({
    required this.file,
    required this.time,
    required this.date,
    this.note,
    this.frameData,
  });
}

class CameraPhotoCard extends StatelessWidget {
  const CameraPhotoCard(this.time, this.date, {super.key, this.imageFile, this.frameData});

  final String time;
  final String date;
  final File? imageFile;
  final Uint8List? frameData;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200.h,
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(16.r),
        image: imageFile != null
            ? DecorationImage(
          image: FileImage(imageFile!),
          fit: BoxFit.cover,
        )
            : frameData != null
            ? DecorationImage(
          image: MemoryImage(frameData!),
          fit: BoxFit.cover,
        )
            : const DecorationImage(
          image: NetworkImage(AppStrings.medicineNetwork),
          fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 12,
            left: 12,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
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
      ),
    );
  }
}