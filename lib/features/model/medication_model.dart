// lib/features/model/medication_model.dart - UPDATED

class MedicationModel {
  String? id;
  String name;
  String time;
  String frequency;           // "daily", "weekly", "monthly", "custom"
  int totalPills;            // NEW: Total pills in slot
  int pillsToDispense;       // NEW: Pills to dispense per time
  int remainingPills;        // NEW: Pills remaining in slot
  String unit;
  bool enabled;
  int slotNumber;
  int? createdAt;
  int? lastRefillDate;       // NEW: When slot was last refilled

  MedicationModel({
    this.id,
    required this.name,
    required this.time,
    this.frequency = 'daily',
    this.totalPills = 0,
    this.pillsToDispense = 1,
    this.remainingPills = 0,
    this.unit = 'pills',
    this.enabled = true,
    this.slotNumber = 0,
    this.createdAt,
    this.lastRefillDate,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'time': time,
      'frequency': frequency,
      'totalPills': totalPills,
      'pillsToDispense': pillsToDispense,
      'remainingPills': remainingPills,
      'unit': unit,
      'enabled': enabled,
      'slotNumber': slotNumber,
      'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
      'lastRefillDate': lastRefillDate,
    };
  }

  // Create from Firebase Map
  factory MedicationModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return MedicationModel(
      id: id,
      name: map['name'] ?? '',
      time: map['time'] ?? '',
      frequency: map['frequency'] ?? 'daily',
      totalPills: map['totalPills'] ?? 0,
      pillsToDispense: map['pillsToDispense'] ?? 1,
      remainingPills: map['remainingPills'] ?? 0,
      unit: map['unit'] ?? 'pills',
      enabled: map['enabled'] ?? true,
      slotNumber: map['slotNumber'] ?? 0,
      createdAt: map['createdAt'],
      lastRefillDate: map['lastRefillDate'],
    );
  }

  // Copy with modified fields
  MedicationModel copyWith({
    String? id,
    String? name,
    String? time,
    String? frequency,
    int? totalPills,
    int? pillsToDispense,
    int? remainingPills,
    String? unit,
    bool? enabled,
    int? slotNumber,
    int? createdAt,
    int? lastRefillDate,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      totalPills: totalPills ?? this.totalPills,
      pillsToDispense: pillsToDispense ?? this.pillsToDispense,
      remainingPills: remainingPills ?? this.remainingPills,
      unit: unit ?? this.unit,
      enabled: enabled ?? this.enabled,
      slotNumber: slotNumber ?? this.slotNumber,
      createdAt: createdAt ?? this.createdAt,
      lastRefillDate: lastRefillDate ?? this.lastRefillDate,
    );
  }

  // Helper methods
  bool get isLowStock => remainingPills < pillsToDispense * 2;
  bool get isEmpty => remainingPills == 0;
  int get percentRemaining => totalPills > 0
      ? ((remainingPills / totalPills) * 100).round()
      : 0;

  String get frequencyDisplay {
    switch (frequency.toLowerCase()) {
      case 'daily':
        return 'Every day';
      case 'weekly':
        return 'Once a week';
      case 'monthly':
        return 'Once a month';
      case 'custom':
        return 'Custom schedule';
      default:
        return frequency;
    }
  }
}