import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String paymentId;
  final String customerId;
  final String? invoiceId;
  final double amount;
  final DateTime paymentDate;
  final String method;
  final String recordedBy;
  final String note;

  PaymentModel({
    required this.paymentId,
    required this.customerId,
    this.invoiceId,
    required this.amount,
    required this.paymentDate,
    this.method = 'cash',
    required this.recordedBy,
    this.note = '',
  });

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: id,
      customerId: map['customerId'] ?? '',
      invoiceId: map['invoiceId'],
      amount: (map['amount'] ?? 0).toDouble(),
      paymentDate:
      (map['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: map['method'] ?? 'cash',
      recordedBy: map['recordedBy'] ?? '',
      note: map['note'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'invoiceId': invoiceId,
    'amount': amount,
    'paymentDate': Timestamp.fromDate(paymentDate),
    'method': method,
    'recordedBy': recordedBy,
    'note': note,
  };
}