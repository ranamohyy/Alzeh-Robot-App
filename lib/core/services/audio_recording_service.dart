import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class AudioRecordingService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static bool _isInitialized = false;

  // ESP32 Configuration - CHANGE THIS TO YOUR ESP32 IP
  static const String ESP32_IP = '192.168.1.70';
  static const int ESP32_PORT = 80;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        print('❌ Microphone permission denied');
        return false;
      }

      await _recorder.openRecorder();
      _isInitialized = true;
      print('✅ AudioRecordingService initialized');
      return true;
    } catch (e) {
      print('❌ AudioRecordingService initialization error: $e');
      return false;
    }
  }

  static Future<bool> startRecording() async {
    try {
      if (!_isInitialized) {
        final success = await initialize();
        if (!success) return false;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/recording_$timestamp.wav';

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,  // WAV format
        bitRate: 256000,
        numChannels: 1,
        sampleRate: 16000,
      );

      print('✅ Recording WAV started: $path');
      return true;
    } catch (e) {
      print('❌ Failed to start recording: $e');
      return false;
    }
  }

  static Future<File?> stopRecording() async {
    try {
      final path = await _recorder.stopRecorder();

      if (path == null) return null;

      final file = File(path);
      if (!await file.exists()) return null;

      final size = await file.length();
      print('✅ Recording stopped: $path (${(size / 1024).toStringAsFixed(1)} KB)');

      return file;
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      return null;
    }
  }

  // --- UPDATED METHOD BELOW ---
  static Future<bool> uploadToESP32(File audioFile, {String? customFilename}) async {
    try {
      final uri = Uri.parse('http://$ESP32_IP:$ESP32_PORT/upload');

      if (!await audioFile.exists()) {
        print('❌ File does not exist: ${audioFile.path}');
        return false;
      }

      final request = http.MultipartRequest('POST', uri);

      // Use the custom filename if provided, otherwise default
      String filename = customFilename ?? 'voice_message.wav';

      request.files.add(
        await http.MultipartFile.fromPath(
          'audio', // Field name expected by ESP32
          audioFile.path,
          filename: filename, // This is what the ESP32 will save it as
        ),
      );

      print('📤 Uploading WAV to ESP32: $uri as $filename');

      final response = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Upload timeout - ESP32 not responding');
        },
      );

      if (response.statusCode == 200) {
        print('✅ Upload successful');
        return true;
      } else {
        print('❌ Upload failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Upload error: $e');
      return false;
    }
  }

  static Future<void> dispose() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
      await _recorder.closeRecorder();
      _isInitialized = false;
    } catch (e) {
      print('❌ Dispose error: $e');
    }
  }
}