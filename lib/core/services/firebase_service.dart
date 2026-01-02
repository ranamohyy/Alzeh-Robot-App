// lib/core/services/firebase_service.dart - FIXED VERSION

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alzeh/features/model/medication_model.dart';
import 'package:alzeh/features/model/user_model.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseDatabase _rtdb = FirebaseDatabase.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get currentUserId => _auth.currentUser?.uid ?? 'user_test_123';

  // ==================== MEDICATION MANAGEMENT (DUAL STORAGE) ====================

  /// Add medication (saves to BOTH Firestore and RTDB)
  static Future<String?> addMedication(MedicationModel medication) async {
    try {
      // 1. Save to Firestore (permanent storage)
      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .add(medication.toMap());

      final medicationId = docRef.id;

      // 2. Sync to RTDB for ESP32 - FIXED PATH
      await _rtdb
          .ref('medications/$currentUserId/$medicationId')
          .set(medication.toMap());

      print('✅ Medication added: $medicationId');
      print('📤 Synced to RTDB at: medications/$currentUserId/$medicationId');

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

      // 1. Update in Firestore
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .doc(medication.id)
          .update(medication.toMap());

      // 2. Update in RTDB for ESP32 - FIXED PATH
      await _rtdb
          .ref('medications/$currentUserId/${medication.id}')
          .update(medication.toMap());

      print('✅ Medication updated: ${medication.id}');
      return true;
    } catch (e) {
      print('❌ Error updating medication: $e');
      return false;
    }
  }

  /// Delete medication (removes from BOTH Firestore and RTDB)
  static Future<bool> deleteMedication(String medicationId) async {
    try {
      // 1. Delete from Firestore
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .doc(medicationId)
          .delete();

      // 2. Remove from RTDB - FIXED PATH
      await _rtdb
          .ref('medications/$currentUserId/$medicationId')
          .remove();

      print('✅ Medication deleted: $medicationId');
      return true;
    } catch (e) {
      print('❌ Error deleting medication: $e');
      return false;
    }
  }

  /// Get medications from Firestore (for app display)
  static Stream<List<MedicationModel>> getMedicationsStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('medications')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
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

      // 2. Update RTDB for ESP32 - FIXED PATH
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
      print('🔄 Starting full sync to RTDB...');
      print('📍 Current User ID: $currentUserId');

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .get();

      print('📦 Found ${snapshot.docs.length} medications in Firestore');

      if (snapshot.docs.isEmpty) {
        print('⚠️  No medications to sync!');
        return;
      }

      // Clear old RTDB data first
      await _rtdb.ref('medications/$currentUserId').remove();
      print('🗑️  Cleared old RTDB data');

      // Sync each medication with detailed logging
      int successCount = 0;
      for (var doc in snapshot.docs) {
        try {
          final medicationId = doc.id;
          final data = doc.data();

          print('');
          print('📤 Syncing medication:');
          print('   ID: $medicationId');
          print('   Name: ${data['name']}');
          print('   Time: ${data['time']}');
          print('   Slot: ${data['slotNumber']}');
          print('   Enabled: ${data['enabled']}');
          print('   Quantity: ${data['quantity']}');

          // Write to RTDB
          final rtdbPath = 'medications/$currentUserId/$medicationId';
          await _rtdb.ref(rtdbPath).set(data);

          print('   ✅ Written to: $rtdbPath');
          successCount++;

        } catch (e) {
          print('   ❌ Failed to sync ${doc.id}: $e');
        }
      }

      print('');
      print('========================================');
      print('✅ Sync Complete!');
      print('   Total: ${snapshot.docs.length}');
      print('   Success: $successCount');
      print('   Failed: ${snapshot.docs.length - successCount}');
      print('   Path: medications/$currentUserId');
      print('========================================');

    } catch (e) {
      print('❌ Error syncing all medications: $e');
      print('Stack trace:');
      print(e);
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
      // ESP32 expects slot numbers 1, 2, 3 (1-based)
      final commandValue = slotNumber + 1;

      print('');
      print('========================================');
      print('📤 SENDING DISPENSE COMMAND');
      print('Medication: $medicationName');
      print('Slot Number: $slotNumber (0-based)');
      print('Command Value: $commandValue (1-based for ESP32)');
      print('========================================');

      // Send command to RTDB
      await _rtdb.ref('commands/device_001/dispense').set(commandValue);

      print('✅ Command sent to: commands/device_001/dispense');
      print('Value: $commandValue');

      // Log command to Firestore for history
      await _firestore.collection('command_logs').add({
        'medicationId': medicationId,
        'medicationName': medicationName,
        'slotNumber': slotNumber,
        'commandValue': commandValue,
        'timestamp': FieldValue.serverTimestamp(),
        'userId': currentUserId,
      });

      return true;
    } catch (e) {
      print('❌ Error sending dispense command: $e');
      return false;
    }
  }

  /// Check ESP32 connection status
  static Future<Map<String, dynamic>> getESP32Status() async {
    try {
      final snapshot = await _rtdb.ref('esp32_status/device_001').get();

      if (snapshot.exists) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        print('📊 ESP32 Status: $data');
        return data;
      }

      print('⚠️  No ESP32 status found');
      return {'connected': false};
    } catch (e) {
      print('❌ Error getting ESP32 status: $e');
      return {'connected': false, 'error': e.toString()};
    }
  }

  /// Listen to ESP32 status updates
  static Stream<Map<String, dynamic>> getESP32StatusStream() {
    return _rtdb.ref('esp32_status/device_001').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {'connected': false};
    });
  }

  // ==================== USER MANAGEMENT (FIRESTORE) ====================

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

  // ==================== MEDICATION LOGS (FIRESTORE) ====================

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

  /// Force full sync from Firestore to RTDB
  static Future<void> forceFullSync() async {
    print('');
    print('🔄 FORCE FULL SYNC INITIATED');
    await syncAllMedicationsToRTDB();
    print('✅ FORCE FULL SYNC COMPLETE');
    print('');
  }

  /// Debug: Print current RTDB structure
  static Future<void> debugPrintRTDB() async {
    try {
      print('');
      print('========================================');
      print('🔍 DEBUGGING RTDB STRUCTURE');
      print('========================================');

      // Check medications
      final medsSnapshot = await _rtdb.ref('medications/$currentUserId').get();
      if (medsSnapshot.exists) {
        print('📦 Medications found:');
        final medsMap = Map<String, dynamic>.from(medsSnapshot.value as Map);
        medsMap.forEach((key, value) {
          print('   ID: $key');
          if (value is Map) {
            final med = Map<String, dynamic>.from(value);
            print('      Name: ${med['name']}');
            print('      Time: ${med['time']}');
            print('      Slot: ${med['slotNumber']}');
            print('      Enabled: ${med['enabled']}');
          }
        });
      } else {
        print('❌ No medications found in RTDB!');
      }

      // Check commands
      final cmdSnapshot = await _rtdb.ref('commands/device_001').get();
      if (cmdSnapshot.exists) {
        print('');
        print('📨 Commands found:');
        print(cmdSnapshot.value);
      } else {
        print('');
        print('📭 No commands in RTDB');
      }

      // Check ESP32 status
      final statusSnapshot = await _rtdb.ref('esp32_status/device_001').get();
      if (statusSnapshot.exists) {
        print('');
        print('📊 ESP32 Status:');
        print(statusSnapshot.value);
      } else {
        print('');
        print('⚠️  No ESP32 status in RTDB');
      }

      print('========================================');
      print('');
    } catch (e) {
      print('❌ Error debugging RTDB: $e');
    }
  }
}