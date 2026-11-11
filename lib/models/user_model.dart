import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role;
  final String name;
  final String nickname;
  final String phone;
  final String email;
  final String emergencyContact;
  final double ratePerKg;
  final DeliveryAddress address;
  final bool isBlocked;
  final bool isDead;
  final DateTime createdAt;
  final double outstandingBalance;

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    this.nickname = '',
    required this.phone,
    required this.email,
    this.emergencyContact = '',
    this.ratePerKg = 0.0,
    required this.address,
    this.isBlocked = false,
    this.isDead = false,
    required this.createdAt,
    this.outstandingBalance = 0.0,
  });

  /// Short display name for compact UI (spreadsheet, lists)
  String get displayName => nickname.isNotEmpty ? nickname : name;

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      role: (map['role'] ?? 'customer') as String,
      name: (map['name'] ?? '') as String,
      nickname: (map['nickname'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      email: (map['email'] ?? '') as String,
      emergencyContact: (map['emergencyContact'] ?? '') as String,
      ratePerKg: ((map['ratePerKg'] ?? 0) as num).toDouble(),
      address: DeliveryAddress.fromMap(
          (map['address'] as Map<String, dynamic>?) ?? {}),
      isBlocked: (map['isBlocked'] ?? false) as bool,
      isDead: (map['isDead'] ?? false) as bool,
      createdAt:
      (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      outstandingBalance:
      ((map['outstandingBalance'] ?? 0) as num).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'role': role,
    'name': name,
    'nickname': nickname,
    'phone': phone,
    'email': email,
    'emergencyContact': emergencyContact,
    'ratePerKg': ratePerKg,
    'address': address.toMap(),
    'isBlocked': isBlocked,
    'isDead': isDead,
    'createdAt': Timestamp.fromDate(createdAt),
    'outstandingBalance': outstandingBalance,
  };
}

class DeliveryAddress {
  final String fullAddress;
  final double lat;
  final double lng;
  final String instructions;

  DeliveryAddress({
    required this.fullAddress,
    this.lat = 0.0,
    this.lng = 0.0,
    this.instructions = '',
  });

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      fullAddress: (map['fullAddress'] ?? '') as String,
      lat: ((map['lat'] ?? 0) as num).toDouble(),
      lng: ((map['lng'] ?? 0) as num).toDouble(),
      instructions: (map['instructions'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'fullAddress': fullAddress,
    'lat': lat,
    'lng': lng,
    'instructions': instructions,
  };
}