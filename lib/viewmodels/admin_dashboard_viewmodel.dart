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

    // ── Phase 1: cache (instant, works offline) ─────────────
    await _fetchAll(Source.cache);

    // Turn off the spinner as soon as we've tried the cache,
    // even if the cache was empty. No endless waiting offline.
    _loading = false;
    notifyListeners();

    // ── Phase 2: server (silent background update) ─────────
    await _fetchAll(Source.server);

    notifyListeners();
  }

  /// Fetches all 5 dashboard metrics from the given source.
  /// Each query is isolated so one failure doesn't stop the rest.
  Future<void> _fetchAll(Source source) async {
    final opts = GetOptions(source: source);

    // Customers + total outstanding
    try {
      final customers = await _db
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get(opts);
      _totalCustomers = customers.docs.length;
      double outstanding = 0;
      for (final c in customers.docs) {
        outstanding +=
            ((c.data()['outstandingBalance'] ?? 0) as num).toDouble();
      }
      _pendingPayments = outstanding;
      notifyListeners();
    } catch (_) {}

    // Today's orders
    try {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      final todays = await _db
          .collection('orders')
          .where('createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
          .get(opts);
      _todayOrders = todays.docs.length;
      notifyListeners();
    } catch (_) {}

    // Monthly revenue from deliveries
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);
      final deliveries = await _db
          .collection('delivery_records')
          .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
          .get(opts);
      double revenue = 0;
      for (final d in deliveries.docs) {
        final r = DeliveryRecordModel.fromMap(d.id, d.data());
        revenue += r.amount;
      }
      _monthlyRevenue = revenue;
      notifyListeners();
    } catch (_) {}

    // Active subscriptions
    try {
      final subs = await _db
          .collection('subscriptions')
          .where('status', isEqualTo: 'active')
          .get(opts);
      _activeSubs = subs.docs.length;
      notifyListeners();
    } catch (_) {}
  }
}