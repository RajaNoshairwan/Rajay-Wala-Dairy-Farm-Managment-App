import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String role; // "customer" | "admin"
  final String name;
  final String phone;
  final String email;
  final DeliveryAddress address;
  final bool isBlocked;
  final DateTime createdAt;
  final double outstandingBalance; // denormalized for quick display

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.isBlocked = false,
    required this.createdAt,
    this.outstandingBalance = 0,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      role: map['role'] ?? 'customer',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: DeliveryAddress.fromMap(map['address'] ?? {}),
      isBlocked: map['isBlocked'] ?? false,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      outstandingBalance: (map['outstandingBalance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'role': role,
    'name': name,
    'phone': phone,
    'email': email,
    'address': address.toMap(),
    'isBlocked': isBlocked,
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
    this.lat = 0,
    this.lng = 0,
    this.instructions = '',
  });

  factory DeliveryAddress.fromMap(Map<String, dynamic> map) {
    return DeliveryAddress(
      fullAddress: map['fullAddress'] ?? '',
      lat: (map['lat'] ?? 0).toDouble(),
      lng: (map['lng'] ?? 0).toDouble(),
      instructions: map['instructions'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'fullAddress': fullAddress,
    'lat': lat,
    'lng': lng,
    'instructions': instructions,
  };
}