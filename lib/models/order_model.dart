import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String orderId;
  final String customerId;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final String deliveryAddress;
  final double lat;
  final double lng;
  final String instructions;
  final double tip;
  final String paymentMethod;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrderModel({
    required this.orderId,
    required this.customerId,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.deliveryAddress,
    this.lat = 0,
    this.lng = 0,
    this.instructions = '',
    this.tip = 0,
    this.paymentMethod = 'COD',
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrderModel.fromMap(String id, Map<String, dynamic> map) {
    return OrderModel(
      orderId: id,
      customerId: map['customerId'] ?? '',
      items: (map['items'] as List? ?? [])
          .map((e) => OrderItem.fromMap(e))
          .toList(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      status: map['status'] ?? 'pending',
      deliveryAddress: map['deliveryAddress']?['fullAddress'] ?? '',
      lat: (map['deliveryAddress']?['lat'] ?? 0).toDouble(),
      lng: (map['deliveryAddress']?['lng'] ?? 0).toDouble(),
      instructions: map['instructions'] ?? '',
      tip: (map['tip'] ?? 0).toDouble(),
      paymentMethod: map['paymentMethod'] ?? 'COD',
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'items': items.map((e) => e.toMap()).toList(),
    'totalAmount': totalAmount,
    'status': status,
    'deliveryAddress': {
      'fullAddress': deliveryAddress,
      'lat': lat,
      'lng': lng,
    },
    'instructions': instructions,
    'tip': tip,
    'paymentMethod': paymentMethod,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': Timestamp.fromDate(updatedAt),
  };
}

class OrderItem {
  final String productId;
  final String productName;
  final double quantityLitres;
  final double pricePerLitre;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantityLitres,
    required this.pricePerLitre,
  });

  factory OrderItem.fromMap(Map<String, dynamic> map) => OrderItem(
    productId: map['productId'] ?? '',
    productName: map['productName'] ?? '',
    quantityLitres: (map['quantityLitres'] ?? 0).toDouble(),
    pricePerLitre: (map['pricePerLitre'] ?? 0).toDouble(),
  );

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'productName': productName,
    'quantityLitres': quantityLitres,
    'pricePerLitre': pricePerLitre,
  };

  double get amount => quantityLitres * pricePerLitre;
}