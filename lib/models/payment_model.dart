import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentModel {
  final String paymentId;
  final String customerId;
  final String? invoiceId;
  final double amount;
  final DateTime paymentDate;
  final String method; // 'cash' | 'online'
  final String status; // 'received' | 'pending'
  final String recordedBy;
  final String note;

  PaymentModel({
    required this.paymentId,
    required this.customerId,
    this.invoiceId,
    required this.amount,
    required this.paymentDate,
    this.method = 'cash',
    this.status = 'received',
    required this.recordedBy,
    this.note = '',
  });

  factory PaymentModel.fromMap(String id, Map<String, dynamic> map) {
    return PaymentModel(
      paymentId: id,
      customerId: (map['customerId'] ?? '') as String,
      invoiceId: map['invoiceId'] as String?,
      amount: ((map['amount'] ?? 0) as num).toDouble(),
      paymentDate:
      (map['paymentDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      method: (map['method'] ?? 'cash') as String,
      status: (map['status'] ?? 'received') as String,
      recordedBy: (map['recordedBy'] ?? '') as String,
      note: (map['note'] ?? '') as String,
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'invoiceId': invoiceId,
    'amount': amount,
    'paymentDate': Timestamp.fromDate(paymentDate),
    'method': method,
    'status': status,
    'recordedBy': recordedBy,
    'note': note,
  };
}