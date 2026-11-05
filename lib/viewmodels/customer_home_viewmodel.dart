// import 'package:flutter/material.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class CustomerHomeViewModel extends ChangeNotifier {
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   double _outstanding = 0;
//   int _pendingOrders = 0;
//   int _activeSubs = 0;
//   bool _loading = true;
//
//   double get outstanding => _outstanding;
//   int get pendingOrders => _pendingOrders;
//   int get activeSubs => _activeSubs;
//   bool get loading => _loading;
//
//   Future<void> load(String customerId) async {
//     _loading = true;
//     notifyListeners();
//
//     final userDoc = await _db.collection('users').doc(customerId).get();
//     _outstanding =
//         ((userDoc.data()?['outstandingBalance'] ?? 0) as num).toDouble();
//
//     final orders = await _db
//         .collection('orders')
//         .where('customerId', isEqualTo: customerId)
//         .where('status', isEqualTo: 'pending')
//         .get();
//     _pendingOrders = orders.docs.length;
//
//     final subs = await _db
//         .collection('subscriptions')
//         .where('customerId', isEqualTo: customerId)
//         .where('status', isEqualTo: 'active')
//         .get();
//     _activeSubs = subs.docs.length;
//
//     _loading = false;
//     notifyListeners();
//   }
// }



import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerHomeViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  double _outstanding = 0;
  int _pendingOrders = 0, _activeSubs = 0;
  bool _loading = true;

  double get outstanding => _outstanding;
  int get pendingOrders => _pendingOrders;
  int get activeSubs => _activeSubs;
  bool get loading => _loading;

  Future<void> load(String customerId) async {
    _loading = true;
    notifyListeners();
    try {
      final userDoc = await _db.collection('users').doc(customerId).get();
      _outstanding =
          ((userDoc.data()?['outstandingBalance'] ?? 0) as num).toDouble();

      final orders = await _db
          .collection('orders')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'pending')
          .get();
      _pendingOrders = orders.docs.length;

      final subs = await _db
          .collection('subscriptions')
          .where('customerId', isEqualTo: customerId)
          .where('status', isEqualTo: 'active')
          .get();
      _activeSubs = subs.docs.length;
    } catch (e) {
      debugPrint('Home load error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}