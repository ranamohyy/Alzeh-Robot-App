// lib/core/services/firebase_service.dart
// HYBRID: Firestore for storage + RTDB for ESP32 sync

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alzeh/features/model/medication_model.dart';
import 'package:alzeh/features/model/user_model.dart';

class FirebaseService {
  // Firestore (permanent storage)
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Realtime Database (ESP32 sync)
  static final FirebaseDatabase _rtdb = FirebaseDatabase.instance;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static String get currentUserId => _auth.currentUser?.uid ?? 'user_test_123';

  // ==================== USER MANAGEMENT (FIRESTORE) ====================

  /// Save user profile to Firestore
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

  /// Get user profile from Firestore
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

  /// Stream user profile from Firestore
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

      // 2. Sync to RTDB for ESP32
      await _syncMedicationToRTDB(medicationId, medication);

      return medicationId;
    } catch (e) {
      print('Error adding medication: $e');
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

      // 2. Sync to RTDB for ESP32
      await _syncMedicationToRTDB(medication.id!, medication);

      return true;
    } catch (e) {
      print('Error updating medication: $e');
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

      // 2. Remove from RTDB
      await _rtdb
          .ref('medications/$currentUserId/$medicationId')
          .remove();

      return true;
    } catch (e) {
      print('Error deleting medication: $e');
      return false;
    }
  }

  /// Sync single medication to RTDB (for ESP32)
  static Future<void> _syncMedicationToRTDB(
      String medicationId,
      MedicationModel medication,
      ) async {
    try {
      await _rtdb
          .ref('medications/$currentUserId/$medicationId')
          .set(medication.toMap());
    } catch (e) {
      print('Error syncing to RTDB: $e');
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

  /// Get single medication from Firestore
  static Future<MedicationModel?> getMedication(String medicationId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .doc(medicationId)
          .get();

      if (doc.exists) {
        return MedicationModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting medication: $e');
      return null;
    }
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

      return true;
    } catch (e) {
      print('Error toggling medication status: $e');
      return false;
    }
  }

  /// Sync ALL medications from Firestore to RTDB
  /// (Useful for initial setup or after bulk changes)
  static Future<void> syncAllMedicationsToRTDB() async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .get();

      // Clear old RTDB data
      await _rtdb.ref('medications/$currentUserId').remove();

      // Sync each medication
      for (var doc in snapshot.docs) {
        final medication = MedicationModel.fromMap(doc.id, doc.data());
        await _syncMedicationToRTDB(doc.id, medication);
      }

      print('Synced ${snapshot.docs.length} medications to RTDB');
    } catch (e) {
      print('Error syncing all medications: $e');
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

      print('📤 Sending dispense command: Slot $commandValue');

      await _rtdb.ref('commands/device_001/dispense').set(commandValue);

      print('✅ Command sent successfully!');

      // Log command to Firestore for history
      await _firestore
          .collection('command_logs')
          .add({
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

  /// Listen to ESP32 status from RTDB
  static Stream<Map<String, dynamic>> getESP32StatusStream() {
    return _rtdb.ref('status/device_001').onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }

  /// Check if ESP32 is connected
  static Future<bool> isESP32Connected() async {
    try {
      final snapshot = await _rtdb.ref('status/device_001/lastSeen').get();
      if (snapshot.exists) {
        final lastSeen = snapshot.value as int;
        final now = DateTime.now().millisecondsSinceEpoch;
        return (now - lastSeen) < 60000; // Connected if seen in last 60s
      }
      return false;
    } catch (e) {
      print('Error checking ESP32 status: $e');
      return false;
    }
  }

  // ==================== MEDICATION LOGS (FIRESTORE) ====================

  /// Log medication taken to Firestore
  static Future<bool> logMedicationTaken(
      String medicationId,
      String medicationName,
      String status, // 'taken', 'missed', 'skipped'
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

  /// Get logs for a specific date from Firestore
  static Stream<List<Map<String, dynamic>>> getMedicationLogsStream(
      DateTime date) {
    final dateString = date.toIso8601String().split('T')[0];

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('medication_logs')
        .where('date', isEqualTo: dateString)
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  /// Get all logs from Firestore
  static Stream<List<Map<String, dynamic>>> getAllMedicationLogsStream() {
    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('medication_logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  // ==================== STATISTICS (FIRESTORE) ====================

  /// Get medication adherence statistics
  static Future<Map<String, int>> getMedicationStatistics(
      DateTime startDate,
      DateTime endDate,
      ) async {
    try {
      final startDateStr = startDate.toIso8601String().split('T')[0];
      final endDateStr = endDate.toIso8601String().split('T')[0];

      final snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medication_logs')
          .where('date', isGreaterThanOrEqualTo: startDateStr)
          .where('date', isLessThanOrEqualTo: endDateStr)
          .get();

      int taken = 0;
      int missed = 0;
      int skipped = 0;

      for (var doc in snapshot.docs) {
        final status = doc.data()['status'] as String;
        if (status == 'taken') taken++;
        if (status == 'missed') missed++;
        if (status == 'skipped') skipped++;
      }

      return {
        'taken': taken,
        'missed': missed,
        'skipped': skipped,
        'total': taken + missed + skipped,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {'taken': 0, 'missed': 0, 'skipped': 0, 'total': 0};
    }
  }

  // ==================== UTILITY ====================

  /// Force full sync from Firestore to RTDB
  /// Call this when ESP32 first connects or after app reinstall
  static Future<void> forceFullSync() async {
    print('Starting full sync...');
    await syncAllMedicationsToRTDB();
    print('Full sync complete!');
  }
}