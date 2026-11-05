import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createOrder(OrderModel order) async {
    final ref = await _db.collection('orders').add(order.toMap());
    return ref.id;
  }

  Stream<List<OrderModel>> watchCustomerOrders(String customerId) {
    return _db
        .collection('orders')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Stream<List<OrderModel>> watchAllOrders() {
    return _db
        .collection('orders')
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }

  Future<void> updateStatus(String orderId, String status) {
    return _db.collection('orders').doc(orderId).update({
      'status': status,
      'updatedAt': Timestamp.now(),
    });
  }
}