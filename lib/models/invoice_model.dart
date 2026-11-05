import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceModel {
  final String invoiceId;
  final String customerId;
  final int month;
  final int year;
  final double openingBalance;
  final double totalMilkAmount;
  final double paymentsReceived;
  final double closingBalance;
  final String status; // unpaid, partiallyPaid, paid
  final DateTime dueDate;
  final DateTime generatedAt;

  InvoiceModel({
    required this.invoiceId,
    required this.customerId,
    required this.month,
    required this.year,
    required this.openingBalance,
    required this.totalMilkAmount,
    required this.paymentsReceived,
    required this.closingBalance,
    required this.status,
    required this.dueDate,
    required this.generatedAt,
  });

  factory InvoiceModel.fromMap(String id, Map<String, dynamic> map) {
    return InvoiceModel(
      invoiceId: id,
      customerId: map['customerId'] ?? '',
      month: map['month'] ?? 1,
      year: map['year'] ?? 2026,
      openingBalance: (map['openingBalance'] ?? 0).toDouble(),
      totalMilkAmount: (map['totalMilkAmount'] ?? 0).toDouble(),
      paymentsReceived: (map['paymentsReceived'] ?? 0).toDouble(),
      closingBalance: (map['closingBalance'] ?? 0).toDouble(),
      status: map['status'] ?? 'unpaid',
      dueDate: (map['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      generatedAt:
      (map['generatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'month': month,
    'year': year,
    'openingBalance': openingBalance,
    'totalMilkAmount': totalMilkAmount,
    'paymentsReceived': paymentsReceived,
    'closingBalance': closingBalance,
    'status': status,
    'dueDate': Timestamp.fromDate(dueDate),
    'generatedAt': Timestamp.fromDate(generatedAt),
  };
}