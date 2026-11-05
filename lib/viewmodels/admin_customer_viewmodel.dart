import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/customer_service.dart';

class AdminCustomerViewModel extends ChangeNotifier {
  final CustomerService _service = CustomerService();
  List<UserModel> _customers = [];
  String _search = '';
  bool _loading = false;

  List<UserModel> get customers => _customers.where((c) {
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return c.name.toLowerCase().contains(q) || c.phone.toLowerCase().contains(q);
  }).toList();
  bool get loading => _loading;

  void listen() {
    _loading = true;
    notifyListeners();
    _service.watchAllCustomers().listen(
          (list) { _customers = list; _loading = false; notifyListeners(); },
      onError: (e) { debugPrint('Customers: $e'); _loading = false; notifyListeners(); },
    );
  }

  void search(String q) { _search = q; notifyListeners(); }

  Future<String> createCustomer({
    required String name,
    required String phone,
    required String email,
    required String address,
    required String instructions,
    required double lat,
    required double lng,
  }) async {
    return _service.createCustomer(UserModel(
      uid: '',
      role: 'customer',
      name: name,
      phone: phone,
      email: email,
      address: DeliveryAddress(fullAddress: address, lat: lat, lng: lng, instructions: instructions),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> toggleBlock(UserModel c) => _service.blockCustomer(c.uid, !c.isBlocked);
  Future<void> updateCustomer(String uid, Map<String, dynamic> data) => _service.updateCustomer(uid, data);
}