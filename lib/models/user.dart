import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String name;
  final String cmsId;
  final bool isVerified;
  final bool isSociety;
  final bool isAdmin;
  final DateTime createdAt;

  User({
    required this.uid,
    required this.email,
    required this.name,
    required this.cmsId,
    required this.isVerified,
    required this.isSociety,
    required this.isAdmin,
    required this.createdAt,
  });

  // Factory constructor to create User from Firestore data
  factory User.fromMap(Map<String, dynamic> map) {
    DateTime parsedCreatedAt;

    if (map['createdAt'] is Timestamp) {
      parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
    } else if (map['createdAt'] is String) {
      parsedCreatedAt = DateTime.tryParse(map['createdAt']) ?? DateTime.now();
    } else {
      parsedCreatedAt = DateTime.now();
    }

    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      cmsId: map['cmsId'] ?? '',
      isVerified: map['isVerified'] ?? false,
      isSociety: map['isSociety'] ?? false,
      isAdmin: map['isAdmin'] ?? false,
      createdAt: parsedCreatedAt,
    );
  }

  // Convert User to Firestore-compatible Map
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'name': name,
      'cmsId': cmsId,
      'isVerified': isVerified,
      'isSociety': isSociety,
      'isAdmin': isAdmin,
      'createdAt': createdAt,
    };
  }

  // CopyWith for immutability
  User copyWith({
    String? name,
    String? cmsId,
    bool? isVerified,
    bool? isSociety,
    bool? isAdmin,
  }) {
    return User(
      uid: uid,
      email: email,
      name: name ?? this.name,
      cmsId: cmsId ?? this.cmsId,
      isVerified: isVerified ?? this.isVerified,
      isSociety: isSociety ?? this.isSociety,
      isAdmin: isAdmin ?? this.isAdmin,
      createdAt: createdAt,
    );
  }
}