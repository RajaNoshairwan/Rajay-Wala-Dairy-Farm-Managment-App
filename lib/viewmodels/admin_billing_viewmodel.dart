import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/billing_service.dart';

class AdminBillingViewModel extends ChangeNotifier {
  final BillingService _billingService = BillingService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _loading = false;
  String? _message;

  bool get loading => _loading;
  String? get message => _message;

  Future<void> generateAllInvoices(int month, int year) async {
    _loading = true;
    _message = null;
    notifyListeners();
    try {
      final customers = await _db.collection('users').where('role', isEqualTo: 'customer').get();
      for (final doc in customers.docs) {
        await _billingService.generateMonthlyInvoice(customerId: doc.id, month: month, year: year);
      }
      _message = 'Invoices generated for ${customers.docs.length} customers';
    } catch (e) {
      _message = 'Error: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> recordPayment({
    required String customerId,
    required double amount,
    required String adminUid,
    String? invoiceId,
  }) async {
    try {
      await _billingService.recordPayment(
        customerId: customerId, amount: amount, invoiceId: invoiceId, adminUid: adminUid,
      );
      _message = 'Payment recorded';
      notifyListeners();
      return true;
    } catch (e) {
      _message = 'Error: $e';
      notifyListeners();
      return false;
    }
  }
}