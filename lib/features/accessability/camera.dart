// lib/features/accessability/camera.dart - CONTINUOUS STREAMING VERSION

import 'dart:io';
import 'dart:async';
import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/camera_service.dart';
import 'package:flutter/material.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool isMonitoring = false;
  bool isStreaming = false;
  List<CapturedPhoto> photos = [];

  // For continuous streaming
  String? streamUrl;
  Timer? _refreshTimer;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    streamUrl = CameraService.getStreamUrl();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
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
                        'Continuous live streaming from ESP32-CAM',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Live Stream View (Always visible option)
              if (!isStreaming)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isStreaming = true;
                      _startFrameCounter();
                    });
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Start Live Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50.h),
                  ),
                ),

              // Live Stream Container
              if (isStreaming) ...[
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.black,
                  ),
                  child: Column(
                    children: [
                      // Stream Header
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
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                WidthSpace(8),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14.sp,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Frames: $_frameCount',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12.sp,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // MJPEG Stream View
                      ClipRRect(
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(10.r),
                          bottomRight: Radius.circular(10.r),
                        ),
                        child: Container(
                          height: 300.h,
                          color: Colors.black,
                          child: Image.network(
                            '$streamUrl?timestamp=${DateTime.now().millisecondsSinceEpoch}',
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    HeightSpace(16),
                                    Text(
                                      'Connecting to camera...',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ],
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                      size: 48.r,
                                    ),
                                    HeightSpace(16),
                                    Text(
                                      'Stream Error',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    HeightSpace(8),
                                    Text(
                                      'Check ESP32-CAM connection',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Stream Controls
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            isStreaming = false;
                            _stopFrameCounter();
                          });
                        },
                        icon: const Icon(Icons.stop, size: 18),
                        label: const Text('Stop Stream'),
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
                        label: const Text('Snapshot'),
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
              )),

              // Placeholder if no photos
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
                      HeightSpace(8),
                      Text(
                        'Tap Snapshot while streaming',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey,
                        ),
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

  void _startFrameCounter() {
    _frameCount = 0;
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _frameCount++;
        });
      }
    });
  }

  void _stopFrameCounter() {
    _refreshTimer?.cancel();
    _frameCount = 0;
  }

  Future<void> _captureSnapshot() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            HeightSpace(16),
            const Text('Capturing snapshot...'),
          ],
        ),
      ),
    );

    // Get single frame from ESP32
    final success = await CameraService.captureManualPhoto();

    if (mounted) {
      Navigator.pop(context);

      if (success) {
        final now = DateTime.now();
        setState(() {
          photos.insert(
            0,
            CapturedPhoto(
              file: null, // We'll fetch from ESP32 if needed
              time: TimeOfDay.now().format(context),
              date: '${now.day}/${now.month}/${now.year}',
              note: 'Snapshot from live stream',
            ),
          );
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Snapshot saved!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Snapshot failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
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
            isStreaming = true;
            _startFrameCounter();
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

// Photo data class
class CapturedPhoto {
  final File? file;
  final String time;
  final String date;
  final String? note;

  CapturedPhoto({
    required this.file,
    required this.time,
    required this.date,
    this.note,
  });
}

// Photo card widget
class CameraPhotoCard extends StatelessWidget {
  const CameraPhotoCard(this.time, this.date, {super.key, this.imageFile});

  final String time;
  final String date;
  final File? imageFile;

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