import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionModel {
  final String subscriptionId;
  final String customerId;
  final String productId;
  final double quantityLitres;
  final String planType; // daily, weekly, monthly, customDates
  final DateTime startDate;
  final DateTime endDate;
  final List<DateTime> skipDates;
  final bool isPaused;
  final DateTime? pausedFrom;
  final DateTime? pausedTo;
  final String status; // active, paused, cancelled, expired
  final Map<String, double> quantityOverrides; // "yyyy-MM-dd": litres

  SubscriptionModel({
    required this.subscriptionId,
    required this.customerId,
    required this.productId,
    required this.quantityLitres,
    required this.planType,
    required this.startDate,
    required this.endDate,
    this.skipDates = const [],
    this.isPaused = false,
    this.pausedFrom,
    this.pausedTo,
    this.status = 'active',
    this.quantityOverrides = const {},
  });

  factory SubscriptionModel.fromMap(String id, Map<String, dynamic> map) {
    return SubscriptionModel(
      subscriptionId: id,
      customerId: map['customerId'] ?? '',
      productId: map['productId'] ?? '',
      quantityLitres: (map['quantityLitres'] ?? 1).toDouble(),
      planType: map['planType'] ?? 'daily',
      startDate: (map['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (map['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      skipDates: (map['skipDates'] as List? ?? [])
          .map((e) => (e as Timestamp).toDate())
          .toList(),
      isPaused: map['isPaused'] ?? false,
      pausedFrom: (map['pausedFrom'] as Timestamp?)?.toDate(),
      pausedTo: (map['pausedTo'] as Timestamp?)?.toDate(),
      status: map['status'] ?? 'active',
      quantityOverrides: (map['quantityOverrides'] as Map?)
          ?.map((k, v) => MapEntry(k, (v as num).toDouble())) ??
          {},
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'productId': productId,
    'quantityLitres': quantityLitres,
    'planType': planType,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'skipDates': skipDates.map((d) => Timestamp.fromDate(d)).toList(),
    'isPaused': isPaused,
    'pausedFrom': pausedFrom != null ? Timestamp.fromDate(pausedFrom!) : null,
    'pausedTo': pausedTo != null ? Timestamp.fromDate(pausedTo!) : null,
    'status': status,
    'quantityOverrides': quantityOverrides,
  };
}