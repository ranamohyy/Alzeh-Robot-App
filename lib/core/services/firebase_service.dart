import 'dart:async';
import 'package:firebase_database/firebase_database.dart';
import 'package:alzeh/features/model/medication_model.dart';

class FirebaseService {
  static final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  // Hardcoded for testing
  static String get currentUserId => 'user_test_123';
  static String get deviceId => 'device_001';

  // ==================== 1. DISPENSE COMMAND & COMPLETION ====================

  /// Send dispense command WITHOUT deducting pills
  /// ESP32 will deduct and notify us when done
  static Future<bool> sendDispenseCommand(
      String medicationId,
      String medicationName,
      int slotNumber,
      ) async {
    try {
      print('\n========================================');
      print('💊 SENDING DISPENSE COMMAND');
      print('Medication: $medicationName');
      print('Slot: ${slotNumber + 1}');

      // Clear old completion flags
      await _rtdb.ref('dispenseStatus/$deviceId/completed').remove();

      // Send command (slotNumber is 0-indexed, ESP32 expects 1-indexed)
      await _rtdb.ref('commands/$deviceId/dispense').set({
        'slotNumber': slotNumber + 1,
        'medicationId': medicationId,
        'medicationName': medicationName,
        'timestamp': ServerValue.timestamp,
      });

      print('✅ Command sent to ESP32');
      return true;
    } catch (e) {
      print('❌ Failed to send command: $e');
      return false;
    }
  }

  /// Listen for ESP32 completion signal
  static Stream<Map<String, dynamic>?> listenForDispenseCompletion() {
    print('🎧 Listening for dispense completion...');

    return _rtdb
        .ref('dispenseStatus/$deviceId/completed')
        .onValue
        .map((event) {
      final value = event.snapshot.value;

      if (value != null) {
        print('📥 Completion data received: $value');

        try {
          if (value is Map) {
            return Map<String, dynamic>.from(value);
          } else if (value is String) {
            // Handle string-based completion
            return {'status': 'completed', 'data': value};
          }
        } catch (e) {
          print('⚠️ Error parsing completion data: $e');
        }
      }
      return null;
    });
  }

  /// Clear completion flag
  static Future<void> clearDispenseCompletion() async {
    await _rtdb.ref('dispenseStatus/$deviceId/completed').remove();
  }

  // ==================== 2. MEDICATION CRUD (RTDB ONLY) ====================

  static Future<String?> addMedication(MedicationModel medication) async {
    try {
      // Generate new ID
      final ref = _rtdb.ref('medications/$currentUserId').push();
      final medicationId = ref.key!;

      final medWithId = medication.copyWith(id: medicationId);

      // Save to RTDB
      await ref.set(medWithId.toMap());

      // Update sync token
      await _updateSyncToken();

      print('✅ Medication added: $medicationId');
      return medicationId;
    } catch (e) {
      print('❌ Error adding medication: $e');
      return null;
    }
  }

  static Future<bool> updateMedication(MedicationModel medication) async {
    try {
      if (medication.id == null) return false;

      await _rtdb
          .ref('medications/$currentUserId/${medication.id}')
          .update(medication.toMap());

      await _updateSyncToken();

      print('✅ Medication updated: ${medication.id}');
      return true;
    } catch (e) {
      print('❌ Error updating medication: $e');
      return false;
    }
  }

  static Future<bool> deleteMedication(String medicationId) async {
    try {
      await _rtdb.ref('medications/$currentUserId/$medicationId').remove();
      await _updateSyncToken();

      print('✅ Medication deleted: $medicationId');
      return true;
    } catch (e) {
      print('❌ Error deleting medication: $e');
      return false;
    }
  }

  static Future<void> toggleMedicationStatus(
      String medicationId,
      bool enabled,
      ) async {
    try {
      await _rtdb
          .ref('medications/$currentUserId/$medicationId/enabled')
          .set(enabled);

      await _updateSyncToken();
      print('✅ Status toggled: $medicationId -> $enabled');
    } catch (e) {
      print('❌ Error toggling status: $e');
    }
  }

  /// Get medications stream from RTDB
  static Stream<List<MedicationModel>> getMedicationsStream() {
    return _rtdb
        .ref('medications/$currentUserId')
        .onValue
        .map((event) {
      final data = event.snapshot.value;

      if (data == null) return <MedicationModel>[];

      try {
        final medications = <MedicationModel>[];
        final map = Map<String, dynamic>.from(data as Map);

        map.forEach((key, value) {
          if (key == '_syncToken') return;

          if (value is Map) {
            try {
              final med = MedicationModel.fromMap(
                key,
                Map<String, dynamic>.from(value),
              );
              medications.add(med);
            } catch (e) {
              print('⚠️ Error parsing medication $key: $e');
            }
          }
        });

        // Sort by creation date (newest first)
        medications.sort((a, b) {
          final aTime = a.lastRefillDate ?? 0;
          final bTime = b.lastRefillDate ?? 0;
          return bTime.compareTo(aTime);
        });

        return medications;
      } catch (e) {
        print('❌ Error processing medications stream: $e');
        return <MedicationModel>[];
      }
    });
  }

  // ==================== 3. REFILL SLOT ====================

  static Future<bool> refillSlot(
      String medicationId,
      int newTotalPills,
      ) async {
    try {
      final updates = {
        'totalPills': newTotalPills,
        'remainingPills': newTotalPills,
        'lastRefillDate': DateTime.now().millisecondsSinceEpoch,
      };

      await _rtdb
          .ref('medications/$currentUserId/$medicationId')
          .update(updates);

      await _updateSyncToken();

      print('✅ Slot refilled: $medicationId -> $newTotalPills pills');
      return true;
    } catch (e) {
      print('❌ Error refilling slot: $e');
      return false;
    }
  }

  // ==================== 4. LISTEN FOR ESP32 PILL UPDATES ====================

  /// Listen for ESP32 updating pill counts
  static Stream<Map<String, dynamic>> listenForPillUpdates(String medicationId) {
    return _rtdb
        .ref('medications/$currentUserId/$medicationId/remainingPills')
        .onValue
        .map((event) {
      final value = event.snapshot.value;

      if (value != null && value is int) {
        return {
          'medicationId': medicationId,
          'remainingPills': value,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        };
      }

      return {};
    });
  }

  // ==================== 5. UTILITY & DEBUG ====================

  static Future<void> _updateSyncToken() async {
    await _rtdb
        .ref('medications/$currentUserId/_syncToken')
        .set(DateTime.now().millisecondsSinceEpoch);
  }

  static Future<bool> testConnection() async {
    try {
      print('🔍 Testing RTDB connection...');

      final ref = _rtdb.ref('test_connection');
      await ref.set({
        'timestamp': ServerValue.timestamp,
        'message': 'Hello from Flutter',
      });

      final snapshot = await ref.get();
      await ref.remove();

      return snapshot.exists;
    } catch (e) {
      print('❌ Connection test failed: $e');
      return false;
    }
  }

  static Future<void> debugPrintRTDB() async {
    try {
      print('\n========== RTDB DEBUG ==========');
      final snapshot = await _rtdb.ref().get();

      if (snapshot.exists) {
        print(snapshot.value);
      } else {
        print('⚠️ Database is empty');
      }
      print('================================\n');
    } catch (e) {
      print('❌ Debug print failed: $e');
    }
  }

  static Future<Map<String, dynamic>> getESP32Status() async {
    try {
      final snapshot = await _rtdb.ref('status/$deviceId').get();

      if (snapshot.exists && snapshot.value is Map) {
        return Map<String, dynamic>.from(snapshot.value as Map);
      }

      return {'connected': false, 'message': 'No status found'};
    } catch (e) {
      return {'connected': false, 'error': e.toString()};
    }
  }

  static Future<bool> logMedicationTaken(
      String id,
      String name,
      String status,
      ) async {
    try {
      final ref = _rtdb.ref('logs/$currentUserId').push();

      await ref.set({
        'medicationId': id,
        'medicationName': name,
        'status': status,
        'timestamp': ServerValue.timestamp,
      });

      return true;
    } catch (e) {
      print('❌ Logging failed: $e');
      return false;
    }
  }
}