import 'package:cloud_firestore/cloud_firestore.dart';

class LedgerEntryModel {
  final String entryId;
  final String customerId;
  final DateTime date;
  final String description;
  final double debit; // amount owed (milk delivered, previous balance)
  final double credit; // payment received
  final double balance; // running balance

  LedgerEntryModel({
    required this.entryId,
    required this.customerId,
    required this.date,
    required this.description,
    this.debit = 0,
    this.credit = 0,
    required this.balance,
  });

  factory LedgerEntryModel.fromMap(String id, Map<String, dynamic> map) {
    return LedgerEntryModel(
      entryId: id,
      customerId: map['customerId'] ?? '',
      date: (map['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      description: map['description'] ?? '',
      debit: (map['debit'] ?? 0).toDouble(),
      credit: (map['credit'] ?? 0).toDouble(),
      balance: (map['balance'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'customerId': customerId,
    'date': Timestamp.fromDate(date),
    'description': description,
    'debit': debit,
    'credit': credit,
    'balance': balance,
  };
}