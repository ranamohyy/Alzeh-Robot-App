// lib/features/debug/debug_screen.dart - ENHANCED

import 'package:alzeh/core/resources/barallel.dart';
import 'package:alzeh/core/services/firebase_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  bool _isLoading = false;
  String _output = 'Tap buttons below to debug...';

  Future<void> _testConnection() async {
    setState(() {
      _isLoading = true;
      _output = '🔍 Testing Firebase connections...\n\n';
    });

    try {
      // Test RTDB
      _updateOutput('Testing Realtime Database...');
      final rtdbSuccess = await FirebaseService.testRTDBConnection();

      if (rtdbSuccess) {
        _updateOutput('✅ RTDB connection OK!');
      } else {
        _updateOutput('❌ RTDB connection FAILED!');
        _updateOutput('Check Firebase Console > Realtime Database > Rules');
      }

      _updateOutput('\n---\n');

      // Test Firestore
      _updateOutput('Testing Firestore...');
      try {
        await FirebaseFirestore.instance
            .collection('test')
            .doc('connection')
            .set({'timestamp': DateTime.now().toIso8601String()});
        _updateOutput('✅ Firestore connection OK!');

        await FirebaseFirestore.instance
            .collection('test')
            .doc('connection')
            .delete();
      } catch (e) {
        _updateOutput('❌ Firestore connection FAILED: $e');
        _updateOutput('Check Firebase Console > Firestore > Rules');
      }

      _updateOutput('\n---\n');
      _updateOutput('User ID: ${FirebaseService.currentUserId}');

    } catch (e) {
      _updateOutput('❌ Connection test error: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _syncAll() async {
    setState(() {
      _isLoading = true;
      _output = 'Syncing all medications to RTDB...\n';
    });

    try {
      // Get medications count first
      final medsSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(FirebaseService.currentUserId)
          .collection('medications')
          .get();

      _updateOutput('Found ${medsSnapshot.docs.length} medications in Firestore');

      if (medsSnapshot.docs.isEmpty) {
        _updateOutput('\n⚠️  No medications to sync!');
        _updateOutput('Add medications first using the + button');
      } else {
        // Do the sync
        await FirebaseService.syncAllMedicationsToRTDB();
        _updateOutput('\n✅ Sync complete!');
        _updateOutput('Check ESP32 serial monitor now.');
      }

    } catch (e) {
      _updateOutput('\n❌ Sync failed: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugRTDB() async {
    setState(() {
      _isLoading = true;
      _output = 'Reading RTDB structure...\n';
    });

    await FirebaseService.debugPrintRTDB();

    _updateOutput('✅ Debug complete! Check console/logs for details.');

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _testCommand(int slot) async {
    setState(() {
      _isLoading = true;
      _output = 'Sending test command for Slot $slot...\n';
    });

    _updateOutput('Command will be sent to:');
    _updateOutput('Path: commands/device_001/dispense');
    _updateOutput('Value: $slot (ESP32 slot number)');
    _updateOutput('\n---\n');

    final success = await FirebaseService.sendDispenseCommand(
      'test_id',
      'Test Medication Slot $slot',
      slot - 1, // Convert to 0-based
    );

    if (success) {
      _updateOutput('✅ Command sent successfully!');
      _updateOutput('\nNow check:');
      _updateOutput('1. ESP32 Serial Monitor');
      _updateOutput('2. Firebase Console > Realtime Database');
      _updateOutput('3. Look for: commands/device_001/dispense = $slot');
    } else {
      _updateOutput('❌ Command failed!');
      _updateOutput('Check RTDB permissions');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _checkESP32Status() async {
    setState(() {
      _isLoading = true;
      _output = 'Checking ESP32 status...\n';
    });

    final status = await FirebaseService.getESP32Status();

    _updateOutput('ESP32 Status:');
    _updateOutput(status.toString());

    if (status['connected'] == false) {
      _updateOutput('\n⚠️  ESP32 appears offline');
      _updateOutput('Make sure:');
      _updateOutput('1. ESP32 is powered on');
      _updateOutput('2. WiFi is connected');
      _updateOutput('3. Correct WiFi credentials in code');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _updateOutput(String text) {
    setState(() {
      _output += '\n$text';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: CustomAppBar(
        appBarTiltle: 'Debug Tools',
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.r),
        child: Column(
          spacing: 16.h,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Output Display
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12.r),
              ),
              height: 250.h,
              child: SingleChildScrollView(
                child: Text(
                  _output,
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontSize: 11.sp,
                    height: 1.4,
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // Test Connection Button (MOST IMPORTANT)
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testConnection,
              icon: const Icon(Icons.wifi_tethering),
              label: const Text('1. Test Connection (START HERE)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 55.h),
              ),
            ),

            // Sync Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _syncAll,
              icon: const Icon(Icons.sync),
              label: const Text('2. Force Full Sync to RTDB'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50.h),
              ),
            ),

            // Debug RTDB Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _debugRTDB,
              icon: const Icon(Icons.bug_report),
              label: const Text('3. Debug RTDB Structure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50.h),
              ),
            ),

            // Check ESP32 Status
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkESP32Status,
              icon: const Icon(Icons.device_hub),
              label: const Text('4. Check ESP32 Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50.h),
              ),
            ),

            Divider(thickness: 2),

            Text(
              'Test Dispense Commands',
              style: AppStyles.kTextStyle18Primary,
              textAlign: TextAlign.center,
            ),

            // Test Commands
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _testCommand(1),
                    child: const Text('Slot 1'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                WidthSpace(8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _testCommand(2),
                    child: const Text('Slot 2'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                WidthSpace(8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : () => _testCommand(3),
                    child: const Text('Slot 3'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            HeightSpace(20),

            // Instructions
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.blue.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8.h,
                children: [
                  Text(
                    '📝 Step-by-Step Debug Guide:',
                    style: AppStyles.kTextStyle16Black,
                  ),
                  const Divider(),
                  _buildStep('1', 'Tap "Test Connection" first'),
                  _buildStep('2', 'Add medications using + button'),
                  _buildStep('3', 'Tap "Force Full Sync"'),
                  _buildStep('4', 'Check ESP32 serial monitor'),
                  _buildStep('5', 'Test dispense commands'),
                  const Divider(),
                  Text(
                    '⚠️ If connection test fails:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  _buildStep('•', 'Check Firebase Rules (see below)'),
                  _buildStep('•', 'Verify internet connection'),
                  _buildStep('•', 'Check Firebase Console logs'),
                ],
              ),
            ),

            HeightSpace(10),

            // Firebase Rules Info
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(color: Colors.orange.shade300, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8.h,
                children: [
                  Text(
                    '🔐 Required Firebase Rules:',
                    style: AppStyles.kTextStyle16Black,
                  ),
                  const Divider(),
                  Text(
                    'Go to Firebase Console and set:',
                    style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.bold),
                  ),
                  HeightSpace(4),
                  Text(
                    'Realtime Database Rules:',
                    style: TextStyle(fontSize: 11.sp, color: Colors.blue.shade700),
                  ),
                  Text(
                    '{\n  "rules": {\n    "medications": {".read": true, ".write": true},\n    "commands": {".read": true, ".write": true}\n  }\n}',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontFamily: 'Courier',
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20.w,
            child: Text(
              number,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12.sp),
            ),
          ),
        ],
      ),
    );
  }
}