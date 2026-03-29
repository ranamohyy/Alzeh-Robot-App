// lib/core/services/dispense_listener_service.dart
// BACKGROUND SERVICE TO AUTO-SHOW POST-DISPENSE SCREEN

import 'dart:async';
import 'package:alzeh/core/services/firebase_service.dart';
import 'package:alzeh/features/medication/post_dispense_screen.dart';
import 'package:flutter/material.dart';

class DispenseListenerService {
  static StreamSubscription? _completionSubscription;
  static BuildContext? _appContext;
  static bool _isListening = false;

  /// Initialize the listener with app context
  static void initialize(BuildContext context) {
    _appContext = context;
    if (!_isListening) {
      startListening();
    }
  }

  /// Start listening for ESP32 completion signals
  static void startListening() {
    if (_isListening) return;

    print('🎧 Starting dispense completion listener...');
    _isListening = true;

    _completionSubscription = FirebaseService.listenForDispenseCompletion().listen(
          (completionData) {
        if (completionData != null && _appContext != null) {
          _handleDispenseCompletion(completionData);
        }
      },
      onError: (error) {
        print('❌ Listener error: $error');
      },
    );
  }

  /// Handle dispense completion from ESP32
  static void _handleDispenseCompletion(Map<String, dynamic> data) {
    print('\n========================================');
    print('🔔 DISPENSE COMPLETED BY ESP32!');
    print('Data: $data');

    // Extract medication info
    final medicationName = data['medicationName'] as String? ?? 'Unknown';
    final pillsDispensed = data['pillsDispensed'] as int? ?? 0;

    print('Medication: $medicationName');
    print('Pills: $pillsDispensed');
    print('========================================\n');

    // Navigate to post-dispense screen
    if (_appContext != null && pillsDispensed > 0) {
      Navigator.of(_appContext!).push(
        MaterialPageRoute(
          builder: (context) => PostDispenseScreen(
            medicationName: medicationName,
            pillsDispensed: pillsDispensed,
          ),
        ),
      );

      // Clear the completion flag after navigation
      Future.delayed(const Duration(seconds: 2), () {
        FirebaseService.clearDispenseCompletion();
      });
    }
  }

  /// Stop listening (call when app is disposed)
  static void stopListening() {
    print('🛑 Stopping dispense listener...');
    _completionSubscription?.cancel();
    _completionSubscription = null;
    _isListening = false;
    _appContext = null;
  }

  /// Update context (useful for hot reload or navigation changes)
  static void updateContext(BuildContext context) {
    _appContext = context;
  }
}