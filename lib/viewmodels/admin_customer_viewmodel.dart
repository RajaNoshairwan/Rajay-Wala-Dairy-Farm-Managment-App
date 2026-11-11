import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/customer_service.dart';

class AdminCustomerViewModel extends ChangeNotifier {
  final CustomerService _service = CustomerService();
  List<UserModel> _customers = [];
  String _search = '';
  bool _loading = false;

  /// Live customers only (isDead == false), filtered by search
  List<UserModel> get customers => _customers.where((c) {
    if (c.isDead) return false;
    if (_search.isEmpty) return true;
    final q = _search.toLowerCase();
    return c.name.toLowerCase().contains(q) ||
        c.nickname.toLowerCase().contains(q) ||
        c.phone.toLowerCase().contains(q) ||
        c.emergencyContact.toLowerCase().contains(q);
  }).toList();

  /// Dead customers only
  List<UserModel> get deadCustomers =>
      _customers.where((c) => c.isDead).toList();

  bool get loading => _loading;
  List<UserModel> get allCustomers => _customers;

  void listen() {
    _loading = true;
    notifyListeners();
    _service.watchAllCustomers().listen(
          (list) {
        _customers = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Customers stream error: $e');
        _loading = false;
        notifyListeners();
      },
    );
  }

  void search(String q) {
    _search = q;
    notifyListeners();
  }

  Future<String> createCustomer({
    required String name,
    required String nickname,
    required String phone,
    required String emergencyContact,
    required double ratePerKg,
    required String address,
    required String instructions,
    required double lat,
    required double lng,
  }) async {
    return _service.createCustomer(UserModel(
      uid: '',
      role: 'customer',
      name: name,
      nickname: nickname,
      phone: phone,
      email: '',
      emergencyContact: emergencyContact,
      ratePerKg: ratePerKg,
      address: DeliveryAddress(
        fullAddress: address,
        lat: lat,
        lng: lng,
        instructions: instructions,
      ),
      createdAt: DateTime.now(),
    ));
  }

  Future<void> markDead(UserModel c, bool isDead) =>
      _service.setDead(c.uid, isDead);

  Future<void> toggleBlock(UserModel c) =>
      _service.blockCustomer(c.uid, !c.isBlocked);

  Future<void> updateCustomer(String uid, Map<String, dynamic> data) =>
      _service.updateCustomer(uid, data);
}