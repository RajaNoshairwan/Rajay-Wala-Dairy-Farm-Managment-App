import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderViewModel extends ChangeNotifier {
  final OrderService _service = OrderService();
  List<OrderModel> _orders = [];
  bool _loading = false;

  List<OrderModel> get orders => _orders;
  bool get loading => _loading;

  void listenCustomer(String customerId) {
    _loading = true;
    notifyListeners();
    _service.watchCustomerOrders(customerId).listen(
          (list) { _orders = list; _loading = false; notifyListeners(); },
      onError: (e) { debugPrint('Orders: $e'); _loading = false; notifyListeners(); },
    );
  }

  Future<void> cancel(String id) => _service.updateStatus(id, 'cancelled');
}