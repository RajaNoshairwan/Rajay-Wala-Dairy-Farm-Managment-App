import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class AdminOrderViewModel extends ChangeNotifier {
  final OrderService _service = OrderService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  List<OrderModel> _orders = [];
  Map<String, String> _names = {};
  String _filter = 'all';
  bool _loading = false;

  List<OrderModel> get orders => _filter == 'all' ? _orders : _orders.where((o) => o.status == _filter).toList();
  bool get loading => _loading;
  String get filter => _filter;
  String nameFor(String customerId) => _names[customerId] ?? customerId;

  void listen() {
    _loading = true;
    notifyListeners();
    _loadNames();
    _service.watchAllOrders().listen(
          (list) { _orders = list; _loading = false; notifyListeners(); },
      onError: (e) { debugPrint('Orders: $e'); _loading = false; notifyListeners(); },
    );
  }

  Future<void> _loadNames() async {
    try {
      final snap = await _db.collection('users').where('role', isEqualTo: 'customer').get();
      _names = {for (var d in snap.docs) d.id: (d.data()['name'] ?? '') as String};
      notifyListeners();
    } catch (e) { debugPrint('Names: $e'); }
  }

  void setFilter(String f) { _filter = f; notifyListeners(); }
  Future<void> updateStatus(String id, String status) => _service.updateStatus(id, status);
}