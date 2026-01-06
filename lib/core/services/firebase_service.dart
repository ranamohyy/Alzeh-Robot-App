// lib/core/services/firebase_service.dart - FIXED USER ID

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alzeh/features/model/medication_model.dart';
import 'package:alzeh/features/model/user_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // FIXED: Use the same user ID as ESP32
  static String get currentUserId {
    // For testing: use the hardcoded ESP32 user ID
    // Later: sync this with actual Firebase Auth user
    return 'user_test_123';

    // UNCOMMENT THIS LINE LATER when you want to use real user IDs:
    // return _auth.currentUser?.uid ?? 'user_test_123';
  }

  // ==================== MEDICATION MANAGEMENT (DUAL STORAGE) ====================

  /// Add medication (saves to BOTH Firestore and RTDB)
  static Future<String?> addMedication(MedicationModel medication) async {
    try {
      print('');
      print('========================================');
      print('📤 ADDING MEDICATION');
      print('User ID: $currentUserId');
      print('Medication: ${medication.name}');
      print('Time: ${medication.time}');
      print('Slot: ${medication.slotNumber}');
      print('========================================');

      // 1. Save to Firestore (permanent storage)
      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .add(medication.toMap());

      final medicationId = docRef.id;

      print('✅ Saved to Firestore: users/$currentUserId/medications/$medicationId');

      // 2. Sync to RTDB for ESP32
      final rtdbPath = 'medications/$currentUserId/$medicationId';
      await _rtdb.ref(rtdbPath).set(medication.toMap());

      print('✅ Synced to RTDB: $rtdbPath');
      print('🤖 ESP32 should see this medication within 10 seconds');
      print('========================================');

      return medicationId;
    } catch (e) {
      print('❌ Error adding medication: $e');
      return null;
    }
  }

  /// Update medication (updates BOTH Firestore and RTDB)
  static Future<bool> updateMedication(MedicationModel medication) async {
    try {
      if (medication.id == null) return false;

      print('📝 Updating medication: ${medication.id}');

      // 1. Update in Firestore
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .doc(medication.id)
          .update(medication.toMap());

      // 2. Update in RTDB for ESP32
      await _rtdb
          .ref('medications/$currentUserId/${medication.id}')
          .update(medication.toMap());

      print('✅ Medication updated in both databases');
      return true;
    } catch (e) {
      print('❌ Error updating medication: $e');
      return false;
    }
  }

  /// Delete medication (removes from BOTH Firestore and RTDB)
  static Future<bool> deleteMedication(String medicationId) async {
    try {
      print('🗑️ Deleting medication: $medicationId');

      // 1. Delete from Firestore
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .doc(medicationId)
          .delete();

      // 2. Remove from RTDB
      await _rtdb
          .ref('medications/$currentUserId/$medicationId')
          .remove();

      print('✅ Medication deleted from both databases');
      return true;
    } catch (e) {
      print('❌ Error deleting medication: $e');
      return false;
    }
  }

  /// Get medications from Firestore (for app display)
  static Stream<List<MedicationModel>> getMedicationsStream() {
    print('📊 Streaming medications for user: $currentUserId');

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📦 Received ${snapshot.docs.length} medications from Firestore');
      return snapshot.docs.map((doc) {
        return MedicationModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  /// Toggle medication status (updates BOTH)
  static Future<bool> toggleMedicationStatus(
      String medicationId,
      bool enabled,
      ) async {
    try {
      // 1. Update Firestore
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .doc(medicationId)
          .update({
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update RTDB for ESP32
      await _rtdb
          .ref('medications/$currentUserId/$medicationId/enabled')
          .set(enabled);

      print('✅ Medication ${enabled ? 'enabled' : 'disabled'}: $medicationId');
      return true;
    } catch (e) {
      print('❌ Error toggling medication status: $e');
      return false;
    }
  }

  /// Sync ALL medications from Firestore to RTDB
  static Future<void> syncAllMedicationsToRTDB() async {
    try {
      print('');
      print('========================================');
      print('🔄 FULL SYNC TO RTDB');
      print('User ID: $currentUserId');
      print('ESP32 will read from: medications/$currentUserId/');
      print('========================================');

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .get();

      print('📦 Found ${snapshot.docs.length} medications in Firestore');

      if (snapshot.docs.isEmpty) {
        print('⚠️  No medications to sync!');
        print('Add medications first using the + button');
        return;
      }

      // Clear old RTDB data first
      await _rtdb.ref('medications/$currentUserId').remove();
      print('🗑️  Cleared old RTDB data');

      // Sync each medication
      int successCount = 0;
      for (var doc in snapshot.docs) {
        try {
          final medicationId = doc.id;
          final data = doc.data();

          print('');
          print('📤 Syncing: ${data['name']}');
          print('   ID: $medicationId');
          print('   Time: ${data['time']}');
          print('   Slot: ${data['slotNumber']}');
          print('   Quantity: ${data['quantity']}');
          print('   Enabled: ${data['enabled']}');

          // Write to RTDB
          final rtdbPath = 'medications/$currentUserId/$medicationId';
          await _rtdb.ref(rtdbPath).set(data);

          print('   ✅ Written to: $rtdbPath');
          successCount++;

        } catch (e) {
          print('   ❌ Failed: $e');
        }
      }

      print('');
      print('========================================');
      print('✅ SYNC COMPLETE!');
      print('   Total: ${snapshot.docs.length}');
      print('   Success: $successCount');
      print('   Failed: ${snapshot.docs.length - successCount}');
      print('');
      print('🤖 ESP32 should now see these medications!');
      print('   Check ESP32 serial monitor...');
      print('========================================');

    } catch (e) {
      print('❌ Error syncing: $e');
    }
  }

  // ==================== ESP32 COMMANDS (RTDB ONLY) ====================

  /// Send dispense command to ESP32
  static Future<bool> sendDispenseCommand(
      String medicationId,
      String medicationName,
      int slotNumber,
      ) async {
    try {
      final commandValue = slotNumber + 1;

      print('');
      print('========================================');
      print('📱 SENDING DISPENSE COMMAND');
      print('Path: commands/device_001/dispense');
      print('Value: $commandValue (Slot ${slotNumber + 1})');
      print('Medication: $medicationName');
      print('========================================');

      // Send to RTDB
      await _rtdb.ref('commands/device_001/dispense').set(commandValue);

      print('✅ Command sent!');
      print('🤖 ESP32 should dispense within 2 seconds');
      print('========================================');

      // Log to Firestore (optional)
      try {
        await _firestore
            .collection('users')
            .doc(currentUserId)
            .collection('medication_logs')
            .add({
          'medicationId': medicationId,
          'medicationName': medicationName,
          'slotNumber': slotNumber,
          'commandValue': commandValue,
          'timestamp': FieldValue.serverTimestamp(),
          'status': 'sent',
        });
      } catch (e) {
        print('⚠️  Logging failed (non-critical): $e');
      }

      return true;
    } catch (e) {
      print('❌ Command failed: $e');
      return false;
    }
  }

  /// Check ESP32 status
  static Future<Map<String, dynamic>> getESP32Status() async {
    try {
      final snapshot = await _rtdb.ref('esp32_status/device_001').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('📊 ESP32 Status: $data');
        return data;
      }

      return {'connected': false};
    } catch (e) {
      print('❌ Status check failed: $e');
      return {'connected': false, 'error': e.toString()};
    }
  }

  /// Listen to ESP32 status
  static Stream<Map<String, dynamic>> getESP32StatusStream() {
    return _rtdb.ref('esp32_status/device_001').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {'connected': false};
    });
  }

  // ==================== USER MANAGEMENT ====================

  static Future<bool> saveUserProfile(UserModel user) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .set(user.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error saving user profile: $e');
      return false;
    }
  }

  static Future<UserModel?> getUserProfile() async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .get();

      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting user profile: $e');
      return null;
    }
  }

  static Stream<UserModel?> getUserProfileStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!);
      }
      return null;
    });
  }

  // ==================== MEDICATION LOGS ====================

  static Future<bool> logMedicationTaken(
      String medicationId,
      String medicationName,
      String status,
      ) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medication_logs')
          .add({
        'medicationId': medicationId,
        'medicationName': medicationName,
        'status': status,
        'timestamp': FieldValue.serverTimestamp(),
        'date': DateTime.now().toIso8601String().split('T')[0],
      });

      return true;
    } catch (e) {
      print('Error logging medication: $e');
      return false;
    }
  }

  // ==================== UTILITY ====================

  static Future<void> forceFullSync() async {
    await syncAllMedicationsToRTDB();
  }

  /// Debug RTDB structure
  static Future<void> debugPrintRTDB() async {
    try {
      print('');
      print('========================================');
      print('🔍 RTDB DEBUG INFO');
      print('========================================');
      print('Current User ID: $currentUserId');
      print('Expected ESP32 path: medications/$currentUserId/');
      print('');

      // Check medications
      final medsSnapshot = await _rtdb.ref('medications/$currentUserId').get();
      if (medsSnapshot.exists) {
        print('✅ Medications found in RTDB:');
        final medsMap = Map<String, dynamic>.from(medsSnapshot.value as Map);
        int count = 0;
        medsMap.forEach((key, value) {
          count++;
          print('');
          print('$count. ID: $key');
          if (value is Map) {
            final med = Map<String, dynamic>.from(value);
            print('   Name: ${med['name']}');
            print('   Time: ${med['time']}');
            print('   Slot: ${med['slotNumber']}');
            print('   Enabled: ${med['enabled']}');
            print('   Quantity: ${med['quantity']}');
          }
        });
        print('');
        print('Total: $count medications');
      } else {
        print('❌ No medications in RTDB!');
        print('   Path: medications/$currentUserId');
        print('   Action: Add medications and tap "Force Full Sync"');
      }

      print('');
      print('Commands path: commands/device_001/dispense');
      final cmdSnapshot = await _rtdb.ref('commands/device_001').get();
      if (cmdSnapshot.exists) {
        print('Commands: ${cmdSnapshot.value}');
      } else {
        print('Commands: none');
      }

      print('========================================');
    } catch (e) {
      print('❌ Debug failed: $e');
    }
  }

  /// Test RTDB connection
  static Future<bool> testRTDBConnection() async {
    try {
      print('🔍 Testing RTDB connection...');
      print('User ID: $currentUserId');

      // Write test
      await _rtdb.ref('test/connection').set({
        'timestamp': DateTime.now().toIso8601String(),
        'userId': currentUserId,
      });

      print('✅ RTDB write OK');

      // Read test
      final snapshot = await _rtdb.ref('test/connection').get();
      if (snapshot.exists) {
        print('✅ RTDB read OK');
        print('   Data: ${snapshot.value}');

        // Cleanup
        await _rtdb.ref('test/connection').remove();
        return true;
      }

      return false;
    } catch (e) {
      print('❌ RTDB test failed: $e');
      return false;
    }
  }
}