import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_record_model.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _totalCustomers = 0, _todayOrders = 0, _activeSubs = 0;
  double _monthlyRevenue = 0, _pendingPayments = 0;
  bool _loading = true;

  int get totalCustomers => _totalCustomers;
  int get todayOrders => _todayOrders;
  int get activeSubs => _activeSubs;
  double get monthlyRevenue => _monthlyRevenue;
  double get pendingPayments => _pendingPayments;
  bool get loading => _loading;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      final customers = await _db.collection('users').where('role', isEqualTo: 'customer').get();
      _totalCustomers = customers.docs.length;

      double outstanding = 0;
      for (final c in customers.docs) {
        outstanding += ((c.data()['outstandingBalance'] ?? 0) as num).toDouble();
      }
      _pendingPayments = outstanding;

      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todays = await _db
          .collection('orders')
          .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get();
      _todayOrders = todays.docs.length;

      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);
      final deliveries = await _db
          .collection('delivery_records')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .get();
      double revenue = 0;
      for (final d in deliveries.docs) {
        final r = DeliveryRecordModel.fromMap(d.id, d.data());
        revenue += r.amount;
      }
      _monthlyRevenue = revenue;

      final subs = await _db.collection('subscriptions').where('status', isEqualTo: 'active').get();
      _activeSubs = subs.docs.length;
    } catch (e) {
      debugPrint('Dashboard load error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}