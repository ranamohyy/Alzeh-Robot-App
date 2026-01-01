// lib/features/model/user_model.dart

class UserModel {
  String name;
  String email;
  String phoneNumber;
  String disease;
  String? profileImageUrl;
  int? createdAt;
  int? updatedAt;

  UserModel({
    this.name = 'Mohammed Ayyad',
    this.email = 'Mohammed810@gmail.com',
    this.phoneNumber = '01000459991',
    this.disease = 'diabetes',
    this.profileImageUrl,
    this.createdAt,
    this.updatedAt,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'disease': disease,
      'profileImageUrl': profileImageUrl,
      'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
  }

  // Create from Firestore Map
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      name: map['name'] ?? 'Mohammed Ayyad',
      email: map['email'] ?? 'Mohammed810@gmail.com',
      phoneNumber: map['phoneNumber'] ?? '01000459991',
      disease: map['disease'] ?? 'diabetes',
      profileImageUrl: map['profileImageUrl'],
      createdAt: map['createdAt'],
      updatedAt: map['updatedAt'],
    );
  }

  // Create a copy with modified fields
  UserModel copyWith({
    String? name,
    String? email,
    String? phoneNumber,
    String? disease,
    String? profileImageUrl,
    int? createdAt,
    int? updatedAt,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      disease: disease ?? this.disease,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}