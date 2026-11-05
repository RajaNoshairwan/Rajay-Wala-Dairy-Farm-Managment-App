import 'package:cloud_firestore/cloud_firestore.dart';

class DeliveryRecordModel {
  final String recordId;
  final String customerId;
  final String subscriptionId;
  final DateTime date;
  final double quantityDelivered;
  final double priceAtDelivery;
  final double amount;
  final String status; // delivered, skipped, missed
  final String? deliveryStaffId;
  final DateTime recordedAt;

  DeliveryRecordModel({
    required this.recordId,
    required this.customerId,
    required this.subscriptionId,
    required this.date,
    required this.quantityDelivered,
    required this.priceAtDelivery,
    required this.amount,
    required this.status,
    this.deliveryStaffId,
    required this.recordedAt,
  });

  factory DeliveryRecordModel.fromMap(String id, Map<String, dynamic> map) {
    return DeliveryRecordModel(
      recordId: id,
      customerId: map['customerId'] ?? '',
      subscriptionId: map['subscriptionId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      quantityDelivered: (map['quantityDelivered'] ?? 0).toDouble(),
      priceAtDelivery: (map['priceAtDelivery'] ?? 0).toDouble(),
      amount: (map['amount'] ?? 0).toDouble(),
      status: map['status'] ?? 'delivered',
      deliveryStaffId: map['deliveryStaffId'],
      recordedAt: (map['recordedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'subscriptionId': subscriptionId,
    'date': Timestamp.fromDate(date),
    'quantityDelivered': quantityDelivered,
    'priceAtDelivery': priceAtDelivery,
    'amount': amount,
    'status': status,
    'deliveryStaffId': deliveryStaffId,
    'recordedAt': Timestamp.fromDate(recordedAt),
  };
}