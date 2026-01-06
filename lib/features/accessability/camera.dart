// lib/features/accessability/camera.dart - FIXED PhotoCard naming

import 'dart:io';
import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/camera_service.dart';
import 'package:webview_flutter/webview_flutter.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  bool isMonitoring = false;
  bool isStreaming = false;
  List<CapturedPhoto> photos = []; // RENAMED from PhotoItem

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
                        'Take photos and monitor patient during pill time',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Take Photo Button
              ElevatedButton.icon(
                onPressed: _takePhoto,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Take Photo'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50.h),
                ),
              ),

              // Start/Stop Monitoring
              ElevatedButton.icon(
                onPressed: isMonitoring ? _stopMonitoring : _startMonitoring,
                icon: Icon(isMonitoring ? Icons.stop : Icons.play_arrow),
                label: Text(isMonitoring ? 'Stop Monitoring' : 'Start Auto Monitoring'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isMonitoring ? Colors.red : Colors.green,
                  foregroundColor: Colors.white,
                  minimumSize: Size(double.infinity, 50.h),
                ),
              ),

              // Live Stream Toggle
              if (isMonitoring)
                ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      isStreaming = !isStreaming;
                    });
                  },
                  icon: Icon(isStreaming ? Icons.videocam_off : Icons.videocam),
                  label: Text(isStreaming ? 'Hide Stream' : 'Show Live Stream'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: Size(double.infinity, 50.h),
                  ),
                ),

              // Live Stream View
              if (isStreaming)
                Container(
                  height: 300.h,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.blue, width: 2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10.r),
                    child: WebViewWidget(
                      controller: WebViewController()
                        ..setJavaScriptMode(JavaScriptMode.unrestricted)
                        ..loadRequest(
                          Uri.parse(CameraService.getStreamUrl()),
                        ),
                    ),
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
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    final photo = await CameraService.takePhoto();

    if (photo == null) return;

    final note = await _showNoteDialog();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            HeightSpace(16),
            const Text('Processing photo...'),
          ],
        ),
      ),
    );

    final success = await CameraService.uploadToESP32(photo, note: note);

    if (mounted) {
      Navigator.pop(context);

      if (success) {
        setState(() {
          photos.insert(
            0,
            CapturedPhoto(
              file: photo,
              time: TimeOfDay.now().format(context),
              date: '${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
              note: note,
            ),
          );
        });

        await showSuccessDialog(
          context,
          '✓ Photo Saved!\n\n${note ?? 'No note added'}',
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Photo save failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String?> _showNoteDialog() async {
    final controller = TextEditingController();

    return await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Optional note about this photo...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Skip'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
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
      isStreaming = false;
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

// RENAMED class to avoid conflict
class CapturedPhoto {
  final File file;
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

// RENAMED widget to avoid conflict with photo_card.dart
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