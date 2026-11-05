import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_model.dart';

class PaymentService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<PaymentModel>> getCustomerPayments(String customerId) async {
    final snap = await _db
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('paymentDate', descending: true)
        .get();
    return snap.docs
        .map((d) => PaymentModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<List<PaymentModel>> getAllPayments() async {
    final snap = await _db
        .collection('payments')
        .orderBy('paymentDate', descending: true)
        .get();
    return snap.docs
        .map((d) => PaymentModel.fromMap(d.id, d.data()))
        .toList();
  }
}