// lib/core/services/firebase_service.dart

import 'package:firebase_database/firebase_database.dart';
import 'package:alzeh/features/model/medication_model.dart';

class FirebaseService {
  static final FirebaseDatabase _database = FirebaseDatabase.instance;
  static const String _userId = 'userId_123'; // Replace with actual user ID from auth

  // Get database reference
  static DatabaseReference get _medicationsRef =>
      _database.ref('medications/$_userId');

  static DatabaseReference get _esp32CommandsRef =>
      _database.ref('esp32_commands/device_001');

  // Add new medication
  static Future<String?> addMedication(MedicationModel medication) async {
    try {
      final newMedicationRef = _medicationsRef.push();
      await newMedicationRef.set(medication.toMap());
      return newMedicationRef.key;
    } catch (e) {
      print('Error adding medication: $e');
      return null;
    }
  }

  // Update existing medication
  static Future<bool> updateMedication(MedicationModel medication) async {
    try {
      if (medication.id == null) return false;
      await _medicationsRef.child(medication.id!).update(medication.toMap());
      return true;
    } catch (e) {
      print('Error updating medication: $e');
      return false;
    }
  }

  // Delete medication
  static Future<bool> deleteMedication(String medicationId) async {
    try {
      await _medicationsRef.child(medicationId).remove();
      return true;
    } catch (e) {
      print('Error deleting medication: $e');
      return false;
    }
  }

  // Get all medications
  static Stream<List<MedicationModel>> getMedicationsStream() {
    return _medicationsRef.onValue.map((event) {
      final medications = <MedicationModel>[];
      if (event.snapshot.value != null) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        data.forEach((key, value) {
          medications.add(
            MedicationModel.fromMap(key, Map<dynamic, dynamic>.from(value)),
          );
        });
      }
      return medications;
    });
  }

  // Get single medication
  static Future<MedicationModel?> getMedication(String medicationId) async {
    try {
      final snapshot = await _medicationsRef.child(medicationId).get();
      if (snapshot.exists) {
        return MedicationModel.fromMap(
          medicationId,
          Map<dynamic, dynamic>.from(snapshot.value as Map),
        );
      }
      return null;
    } catch (e) {
      print('Error getting medication: $e');
      return null;
    }
  }

  // Send dispense command to ESP32
  static Future<bool> sendDispenseCommand(
      String medicationId,
      int quantity,
      ) async {
    try {
      await _esp32CommandsRef.child('dispenseMedication').set({
        'medicationId': medicationId,
        'quantity': quantity,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'executed': false,
      });
      return true;
    } catch (e) {
      print('Error sending dispense command: $e');
      return false;
    }
  }

  // Toggle medication enabled status
  static Future<bool> toggleMedicationStatus(
      String medicationId,
      bool enabled,
      ) async {
    try {
      await _medicationsRef.child(medicationId).update({'enabled': enabled});
      return true;
    } catch (e) {
      print('Error toggling medication status: $e');
      return false;
    }
  }

  // Log medication taken
  static Future<bool> logMedicationTaken(
      String medicationId,
      String status, // 'taken', 'missed', 'skipped'
      ) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _database
          .ref('medication_logs/$_userId/$dateKey')
          .push()
          .set({
        'medicationId': medicationId,
        'status': status,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      });
      return true;
    } catch (e) {
      print('Error logging medication: $e');
      return false;
    }
  }

  // Listen to ESP32 status
  static Stream<Map<String, dynamic>> getESP32StatusStream() {
    return _esp32CommandsRef.onValue.map((event) {
      if (event.snapshot.value != null) {
        return Map<String, dynamic>.from(event.snapshot.value as Map);
      }
      return {};
    });
  }
}