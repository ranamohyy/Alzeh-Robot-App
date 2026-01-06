// lib/core/services/camera_service.dart

import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class CameraService {
  static final ImagePicker _picker = ImagePicker();

  // ESP32 Camera IP (UPDATE THIS!)
  static String esp32CameraIP = "192.168.1.101"; // ⚠️ CHANGE TO YOUR ESP32-3 IP

  // ==================== TAKE PHOTO ====================

  static Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) {
        print('📷 Photo cancelled');
        return null;
      }

      final file = File(photo.path);
      print('✅ Photo taken: ${photo.path}');
      print('   Size: ${await file.length()} bytes');

      return file;

    } catch (e) {
      print('❌ Camera error: $e');
      return null;
    }
  }

  // ==================== PICK FROM GALLERY ====================

  static Future<File?> pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (photo == null) {
        print('📷 Selection cancelled');
        return null;
      }

      final file = File(photo.path);
      print('✅ Photo selected: ${photo.path}');
      print('   Size: ${await file.length()} bytes');

      return file;

    } catch (e) {
      print('❌ Gallery error: $e');
      return null;
    }
  }

  // ==================== UPLOAD TO ESP32 CAMERA ====================

  static Future<bool> uploadToESP32(File photoFile, {String? note}) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'photo_$timestamp.jpg';

      print('');
      print('========================================');
      print('📤 UPLOADING TO ESP32 CAMERA');
      print('File: ${photoFile.path}');
      print('Size: ${await photoFile.length()} bytes');
      print('ESP32 IP: $esp32CameraIP');
      print('Filename: $filename');
      if (note != null) print('Note: $note');
      print('========================================');

      // In a real implementation, you might want to:
      // 1. Upload photo to Firebase Storage
      // 2. Store metadata (timestamp, note) in RTDB
      // 3. ESP32 can fetch from Firebase when needed

      // For now, we'll store locally and log
      // (ESP32 CAM doesn't have an upload endpoint in current code)

      print('⚠️  Direct ESP32 upload not available');
      print('Consider using Firebase Storage instead');
      print('========================================');

      return await _uploadToFirebaseStorage(photoFile, note);

    } catch (e) {
      print('❌ Upload error: $e');
      print('========================================');
      return false;
    }
  }

  // ==================== FIREBASE STORAGE UPLOAD ====================

  static Future<bool> _uploadToFirebaseStorage(File photoFile, String? note) async {
    try {
      // TODO: Implement Firebase Storage upload
      // For now, just log

      print('📦 Would upload to Firebase Storage:');
      print('   photos/${DateTime.now().millisecondsSinceEpoch}.jpg');
      print('   Metadata: ${note ?? 'No note'}');

      // Simulate upload
      await Future.delayed(const Duration(seconds: 1));

      return true;

    } catch (e) {
      print('❌ Firebase upload error: $e');
      return false;
    }
  }

  // ==================== START MONITORING ====================

  static Future<bool> startMonitoring({int durationSeconds = 300}) async {
    try {
      print('');
      print('========================================');
      print('👁️  STARTING ESP32 CAMERA MONITORING');
      print('Duration: $durationSeconds seconds');
      print('ESP32 IP: $esp32CameraIP');
      print('========================================');

      final response = await http.post(
        Uri.parse('http://$esp32CameraIP/start?duration=$durationSeconds'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Monitoring started!');
        print('Motion detection active');
        print('========================================');
        return true;
      } else {
        print('❌ Start failed: ${response.statusCode}');
        print('========================================');
        return false;
      }

    } catch (e) {
      print('❌ Start monitoring error: $e');
      print('Make sure:');
      print('1. ESP32-CAM is powered on');
      print('2. Connected to same WiFi');
      print('3. IP address is correct: $esp32CameraIP');
      print('========================================');
      return false;
    }
  }

  // ==================== STOP MONITORING ====================

  static Future<bool> stopMonitoring() async {
    try {
      final response = await http.post(
        Uri.parse('http://$esp32CameraIP/stop'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;

    } catch (e) {
      print('❌ Stop monitoring error: $e');
      return false;
    }
  }

  // ==================== GET STREAM URL ====================

  static String getStreamUrl() {
    return 'http://$esp32CameraIP/stream';
  }

  // ==================== GET STATUS ====================

  static Future<Map<String, dynamic>?> getStatus() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp32CameraIP/status'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        // Parse JSON response
        // return jsonDecode(response.body);
        return {'monitoring': true, 'motion': false};
      }

      return null;

    } catch (e) {
      print('❌ Get status error: $e');
      return null;
    }
  }

  // ==================== GET CAPTURED IMAGES ====================

  static Future<List<String>> getCapturedImages() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp32CameraIP/images'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Parse JSON array of image names
        // return jsonDecode(response.body);
        return [];
      }

      return [];

    } catch (e) {
      print('❌ Get images error: $e');
      return [];
    }
  }

  // ==================== CAPTURE MANUAL PHOTO ====================

  static Future<bool> captureManualPhoto() async {
    try {
      final response = await http.post(
        Uri.parse('http://$esp32CameraIP/capture'),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;

    } catch (e) {
      print('❌ Capture error: $e');
      return false;
    }
  }
}