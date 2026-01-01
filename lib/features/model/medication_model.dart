// lib/features/model/medication_model.dart

class MedicationModel {
  String? id;
  String name;
  String time;
  String frequency;
  int quantity;
  String unit;
  bool enabled;
  int slotNumber; // NEW: Slot assignment (0, 1, or 2)
  int? createdAt;

  MedicationModel({
    this.id,
    required this.name,
    required this.time,
    required this.frequency,
    required this.quantity,
    this.unit = 'pills',
    this.enabled = true,
    this.slotNumber = 0, // Default to slot 0
    this.createdAt,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'time': time,
      'frequency': frequency,
      'quantity': quantity,
      'unit': unit,
      'enabled': enabled,
      'slotNumber': slotNumber, // NEW
      'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Create from Firebase Map
  factory MedicationModel.fromMap(String id, Map<dynamic, dynamic> map) {
    return MedicationModel(
      id: id,
      name: map['name'] ?? '',
      time: map['time'] ?? '',
      frequency: map['frequency'] ?? '',
      quantity: map['quantity'] ?? 0,
      unit: map['unit'] ?? 'pills',
      enabled: map['enabled'] ?? true,
      slotNumber: map['slotNumber'] ?? 0, // NEW
      createdAt: map['createdAt'],
    );
  }

  // Create a copy with modified fields
  MedicationModel copyWith({
    String? id,
    String? name,
    String? time,
    String? frequency,
    int? quantity,
    String? unit,
    bool? enabled,
    int? slotNumber,
    int? createdAt,
  }) {
    return MedicationModel(
      id: id ?? this.id,
      name: name ?? this.name,
      time: time ?? this.time,
      frequency: frequency ?? this.frequency,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      enabled: enabled ?? this.enabled,
      slotNumber: slotNumber ?? this.slotNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}