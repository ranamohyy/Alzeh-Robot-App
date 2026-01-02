// lib/features/debug/debug_screen.dart

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

      setState(() {
        _output += 'Found ${medsSnapshot.docs.length} medications in Firestore\n';
      });

      // Do the sync
      await FirebaseService.syncAllMedicationsToRTDB();

      setState(() {
        _output += '\n✅ Sync complete!\n';
        _output += 'Check your ESP32 serial monitor now.\n';
        _output += 'LCD should show medication data.';
      });

    } catch (e) {
      setState(() {
        _output += '\n❌ Sync failed: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _debugRTDB() async {
    setState(() {
      _isLoading = true;
      _output = 'Reading RTDB structure...';
    });

    await FirebaseService.debugPrintRTDB();

    setState(() {
      _isLoading = false;
      _output = '✅ Debug complete! Check serial monitor/logs.';
    });
  }

  Future<void> _testCommand(int slot) async {
    setState(() {
      _isLoading = true;
      _output = 'Sending test command for Slot $slot...';
    });

    final success = await FirebaseService.sendDispenseCommand(
      'test_id',
      'Test Medication',
      slot - 1, // Convert to 0-based
    );

    setState(() {
      _isLoading = false;
      _output = success
          ? '✅ Command sent! Check ESP32 serial monitor.'
          : '❌ Command failed!';
    });
  }

  Future<void> _checkESP32Status() async {
    setState(() {
      _isLoading = true;
      _output = 'Checking ESP32 status...';
    });

    final status = await FirebaseService.getESP32Status();

    setState(() {
      _isLoading = false;
      _output = 'ESP32 Status:\n${status.toString()}';
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
              height: 200.h,
              child: SingleChildScrollView(
                child: Text(
                  _output,
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontFamily: 'Courier',
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ),

            if (_isLoading)
              const Center(child: CircularProgressIndicator()),

            // Sync Button
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _syncAll,
              icon: const Icon(Icons.sync),
              label: const Text('Force Full Sync to RTDB'),
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
              label: const Text('Debug RTDB Structure'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50.h),
              ),
            ),

            // Check ESP32 Status
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _checkESP32Status,
              icon: const Icon(Icons.wifi),
              label: const Text('Check ESP32 Status'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
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
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 8.h,
                children: [
                  Text(
                    '📝 Instructions:',
                    style: AppStyles.kTextStyle16Black,
                  ),
                  Text(
                    '1. Tap "Force Full Sync" to sync medications',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    '2. Tap "Debug RTDB" to see database structure',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    '3. Check logs/console for detailed output',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    '4. Test dispense commands for each slot',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                  Text(
                    '5. Watch ESP32 serial monitor',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}