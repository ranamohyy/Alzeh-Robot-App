// lib/core/services/firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:alzeh/features/model/medication_model.dart';
import 'package:alzeh/features/model/user_model.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  static String? get currentUserId => _auth.currentUser?.uid ?? 'guest_user';

  // ==================== USER MANAGEMENT ====================

  // Create/Update user profile
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

  // Get user profile
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

  // Stream user profile (realtime)
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

  // ==================== MEDICATION MANAGEMENT ====================

  // Add new medication
  static Future<String?> addMedication(MedicationModel medication) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .add(medication.toMap());

      return docRef.id;
    } catch (e) {
      print('Error adding medication: $e');
      return null;
    }
  }

  // Update medication
  static Future<bool> updateMedication(MedicationModel medication) async {
    try {
      if (medication.id == null) return false;

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .doc(medication.id)
          .update(medication.toMap());

      return true;
    } catch (e) {
      print('Error updating medication: $e');
      return false;
    }
  }

  // Delete medication
  static Future<bool> deleteMedication(String medicationId) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .doc(medicationId)
          .delete();

      return true;
    } catch (e) {
      print('Error deleting medication: $e');
      return false;
    }
  }

  // Get all medications (realtime stream)
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

  // Get single medication
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

  // Toggle medication status
  static Future<bool> toggleMedicationStatus(
      String medicationId, bool enabled) async {
    try {
      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('medications')
          .doc(medicationId)
          .update({
        'enabled': enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      return true;
    } catch (e) {
      print('Error toggling medication status: $e');
      return false;
    }
  }

  // ==================== MEDICATION LOGS ====================

  // Log medication taken
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

  // Get logs for a specific date
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

  // Get all logs (for history)
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

  // ==================== ESP32 COMMANDS ====================

  // Send dispense command to ESP32
  static Future<bool> sendDispenseCommand(
      String medicationId,
      String medicationName,
      int quantity,
      ) async {
    try {
      await _firestore
          .collection('esp32_commands')
          .doc('device_001')
          .collection('commands')
          .add({
        'medicationId': medicationId,
        'medicationName': medicationName,
        'quantity': quantity,
        'timestamp': FieldValue.serverTimestamp(),
        'executed': false,
        'userId': currentUserId,
      });

      return true;
    } catch (e) {
      print('Error sending dispense command: $e');
      return false;
    }
  }

  // Listen to ESP32 status (realtime)
  static Stream<Map<String, dynamic>> getESP32StatusStream() {
    return _firestore
        .collection('esp32_status')
        .doc('device_001')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data() ?? {};
      }
      return {};
    });
  }

  // ==================== STATISTICS ====================

  // Get medication adherence statistics
  static Future<Map<String, int>> getMedicationStatistics(
      DateTime startDate, DateTime endDate) async {
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
}