// lib/core/services/audio_recording_service.dart

import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class AudioRecordingService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static bool _isRecorderInitialized = false;
  static String? _currentRecordingPath;

  // ESP32 Audio Player IP (UPDATE THIS!)
  static String esp32AudioIP = "192.168.1.100"; // ⚠️ CHANGE TO YOUR ESP32-2 IP

  // ==================== INITIALIZATION ====================

  static Future<bool> initialize() async {
    if (_isRecorderInitialized) return true;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        print('❌ Microphone permission denied');
        return false;
      }

      // Open recorder
      await _recorder.openRecorder();
      _isRecorderInitialized = true;

      print('✅ Audio recorder initialized');
      return true;
    } catch (e) {
      print('❌ Audio recorder init failed: $e');
      return false;
    }
  }

  // ==================== RECORDING ====================

  static Future<bool> startRecording() async {
    try {
      if (!_isRecorderInitialized) {
        final success = await initialize();
        if (!success) return false;
      }

      // Get temporary directory
      final dir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      _currentRecordingPath = '${dir.path}/recording_$timestamp.wav';

      // Start recording
      await _recorder.startRecorder(
        toFile: _currentRecordingPath,
        codec: Codec.pcm16WAV, // WAV format for ESP32
        sampleRate: 16000, // 16kHz sample rate
        numChannels: 1, // Mono
      );

      print('🎤 Recording started: $_currentRecordingPath');
      return true;

    } catch (e) {
      print('❌ Start recording failed: $e');
      return false;
    }
  }

  static Future<File?> stopRecording() async {
    try {
      await _recorder.stopRecorder();

      if (_currentRecordingPath == null) {
        print('❌ No recording path');
        return null;
      }

      final file = File(_currentRecordingPath!);

      if (!await file.exists()) {
        print('❌ Recording file not found');
        return null;
      }

      print('✅ Recording stopped: $_currentRecordingPath');
      print('   Size: ${await file.length()} bytes');

      return file;

    } catch (e) {
      print('❌ Stop recording failed: $e');
      return null;
    }
  }

  static bool get isRecording => _recorder.isRecording;

  // ==================== UPLOAD TO ESP32 ====================

  static Future<bool> uploadToESP32(File audioFile, {String? customFilename}) async {
    try {
      final filename = customFilename ?? 'recording_${DateTime.now().millisecondsSinceEpoch}.wav';

      print('');
      print('========================================');
      print('📤 UPLOADING TO ESP32 AUDIO PLAYER');
      print('File: ${audioFile.path}');
      print('Size: ${await audioFile.length()} bytes');
      print('ESP32 IP: $esp32AudioIP');
      print('Filename: $filename');
      print('========================================');

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('http://$esp32AudioIP/upload'),
      );

      // Add file
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          audioFile.path,
          filename: filename,
        ),
      );

      // Send request
      print('Sending...');
      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout');
        },
      );

      if (response.statusCode == 200) {
        print('✅ Upload successful!');
        print('ESP32 saved as: /$filename');
        print('========================================');
        return true;
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        print('========================================');
        return false;
      }

    } catch (e) {
      print('❌ Upload error: $e');
      print('Make sure:');
      print('1. ESP32-2 is powered on');
      print('2. Connected to same WiFi');
      print('3. IP address is correct: $esp32AudioIP');
      print('========================================');
      return false;
    }
  }

  // ==================== PLAY ON ESP32 ====================

  static Future<bool> playOnESP32(String filename) async {
    try {
      print('🔊 Sending play command: $filename');

      final response = await http.post(
        Uri.parse('http://$esp32AudioIP/play?file=$filename'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        print('✅ Playing on ESP32!');
        return true;
      } else {
        print('❌ Play failed: ${response.statusCode}');
        return false;
      }

    } catch (e) {
      print('❌ Play error: $e');
      return false;
    }
  }

  // ==================== STOP PLAYBACK ====================

  static Future<bool> stopPlayback() async {
    try {
      final response = await http.post(
        Uri.parse('http://$esp32AudioIP/stop'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;

    } catch (e) {
      print('❌ Stop error: $e');
      return false;
    }
  }

  // ==================== GET RECORDINGS LIST ====================

  static Future<List<String>> getRecordingsList() async {
    try {
      final response = await http.get(
        Uri.parse('http://$esp32AudioIP/files'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        // Parse JSON array of filenames
        final List<dynamic> files = [];
        // Add parsing logic here based on ESP32 response format
        return files.cast<String>();
      }

      return [];

    } catch (e) {
      print('❌ Get recordings error: $e');
      return [];
    }
  }

  // ==================== CLEANUP ====================

  static Future<void> dispose() async {
    try {
      if (_isRecording) {
        await _recorder.stopRecorder();
      }
      await _recorder.closeRecorder();
      _isRecorderInitialized = false;
      print('✅ Audio recorder disposed');
    } catch (e) {
      print('❌ Dispose error: $e');
    }
  }
}