// lib/core/services/audio_service.dart - Using flutter_sound

import 'dart:io';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;

class AudioService {
  static final FlutterSoundRecorder _recorder = FlutterSoundRecorder();
  static final FlutterSoundPlayer _player = FlutterSoundPlayer();
  static bool _isInitialized = false;

  // ESP32 Configuration - CHANGE THIS TO YOUR ESP32 IP
  static const String ESP32_IP = '192.168.1.70';
  static const int ESP32_PORT = 80;

  static Future<bool> initialize() async {
    if (_isInitialized) return true;

    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        print('❌ Microphone permission denied');
        return false;
      }

      // Open recorder and player
      await _recorder.openRecorder();
      await _player.openPlayer();

      _isInitialized = true;
      print('✅ AudioService initialized');
      return true;
    } catch (e) {
      print('❌ AudioService initialization error: $e');
      return false;
    }
  }

  static Future<String?> startRecording() async {
    try {
      if (!_isInitialized) {
        final success = await initialize();
        if (!success) return null;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final path = '${directory.path}/voice_$timestamp.aac';

      await _recorder.startRecorder(
        toFile: path,
        codec: Codec.aacADTS,
        bitRate: 128000,
        sampleRate: 44100,
      );

      print('✅ Recording started: $path');
      return path;
    } catch (e) {
      print('❌ Failed to start recording: $e');
      return null;
    }
  }

  static Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stopRecorder();

      if (path == null) {
        print('❌ No recording path returned');
        return null;
      }

      final file = File(path);
      if (!await file.exists()) {
        print('❌ Recording file does not exist');
        return null;
      }

      final size = await file.length();
      print('✅ Recording stopped: $path (${(size / 1024).toStringAsFixed(1)} KB)');

      return path;
    } catch (e) {
      print('❌ Failed to stop recording: $e');
      return null;
    }
  }

  static Future<bool> playLocal(String filePath) async {
    try {
      if (!_isInitialized) {
        await initialize();
      }

      await _player.startPlayer(
        fromURI: filePath,
        codec: Codec.aacADTS,
        whenFinished: () {
          print('✅ Playback finished');
        },
      );

      print('✅ Playing local audio: $filePath');
      return true;
    } catch (e) {
      print('❌ Failed to play audio: $e');
      return false;
    }
  }

  static Future<bool> uploadToESP32(String filePath) async {
    try {
      final uri = Uri.parse('http://$ESP32_IP:$ESP32_PORT/upload');
      final file = File(filePath);

      if (!await file.exists()) {
        print('❌ File does not exist: $filePath');
        return false;
      }

      final request = http.MultipartRequest('POST', uri);
      request.files.add(
        await http.MultipartFile.fromPath(
          'audio',
          file.path,
          filename: 'voice_message.aac',
        ),
      );

      print('📤 Uploading to ESP32: $uri');

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

  static Future<bool> playOnESP32() async {
    try {
      final uri = Uri.parse('http://$ESP32_IP:$ESP32_PORT/play');

      print('▶️  Sending play command to ESP32');

      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Play command timeout');
        },
      );

      if (response.statusCode == 200) {
        print('✅ ESP32 playing audio');
        return true;
      } else {
        print('❌ Play command failed: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      print('❌ Play command error: $e');
      return false;
    }
  }

  static Future<void> stopPlayer() async {
    try {
      if (_player.isPlaying) {
        await _player.stopPlayer();
        print('✅ Player stopped');
      }
    } catch (e) {
      print('❌ Stop player error: $e');
    }
  }

  static Future<void> dispose() async {
    try {
      if (_recorder.isRecording) {
        await _recorder.stopRecorder();
      }
      if (_player.isPlaying) {
        await _player.stopPlayer();
      }

      await _recorder.closeRecorder();
      await _player.closePlayer();

      _isInitialized = false;
      print('✅ AudioService disposed');
    } catch (e) {
      print('❌ Dispose error: $e');
    }
  }
}