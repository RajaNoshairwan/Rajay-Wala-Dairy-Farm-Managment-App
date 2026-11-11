import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_record_model.dart';

class AdminDashboardViewModel extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Fixed cost of milk per kg (used for profit calculation).
  /// Profit = (priceAtDelivery − 150) × quantityDelivered, summed.
  static const double costPerKg = 150.0;

  // ── Existing (kept for backward compatibility) ────────────
  int _totalCustomers = 0;
  int _todayOrders = 0;
  int _activeSubs = 0;
  double _pendingPayments = 0;

  // ── Dashboard metrics ─────────────────────────────────────
  double _todaySaleKg = 0;
  double _monthSaleKg = 0;
  double _todayRevenue = 0;
  double _monthRevenue = 0;
  double _todayProfit = 0;
  double _monthProfit = 0;

  bool _loading = true;

  // ── Realtime subscriptions ────────────────────────────────
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _customersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _deliveriesSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subsSub;
  Timer? _midnightTimer;
  Timer? _loadingTimeout;
  bool _listening = false;
  bool _disposed = false;

  // ── Getters (unchanged API) ───────────────────────────────
  int get totalCustomers => _totalCustomers;
  int get todayOrders => _todayOrders;
  int get activeSubs => _activeSubs;
  double get pendingPayments => _pendingPayments;
  double get todaySaleKg => _todaySaleKg;
  double get monthSaleKg => _monthSaleKg;
  double get todayRevenue => _todayRevenue;
  double get monthRevenue => _monthRevenue;
  double get todayProfit => _todayProfit;
  double get monthProfit => _monthProfit;
  bool get loading => _loading;

  /// Called from `initState()` and pull-to-refresh.
  /// Starts (or restarts) all real-time listeners.
  Future<void> load() async {
    if (!_listening) {
      _loading = true;
      notifyListeners();
    }
    _startListeners();
  }

  void _startListeners() {
    _stopListeners();
    _listening = true;

    // Safety net: if no stream emits within 600 ms, hide the spinner so
    // the UI never hangs offline — cached values (or zeros) show
    // immediately and real data fills in when available.
    _loadingTimeout?.cancel();
    _loadingTimeout = Timer(const Duration(milliseconds: 600), () {
      if (_disposed) return;
      if (_loading) {
        _loading = false;
        notifyListeners();
      }
    });

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 1);

    // ── 1. Customers ────────────────────────────────────────
    _customersSub = _db
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .snapshots()
        .listen(
          (snap) {
        _totalCustomers = snap.docs.length;
        double outstanding = 0;
        for (final c in snap.docs) {
          outstanding +=
              ((c.data()['outstandingBalance'] ?? 0) as num).toDouble();
        }
        _pendingPayments = outstanding;
        _afterEmit();
      },
      onError: (e) {
        debugPrint('Customers stream error: $e');
        _afterEmit();
      },
    );

    // ── 2. Today's orders ───────────────────────────────────
    _ordersSub = _db
        .collection('orders')
        .where('createdAt',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .where('createdAt', isLessThan: Timestamp.fromDate(endOfDay))
        .snapshots()
        .listen(
          (snap) {
        _todayOrders = snap.docs.length;
        _afterEmit();
      },
      onError: (e) {
        debugPrint('Orders stream error: $e');
        _afterEmit();
      },
    );

    // ── 3. This-month deliveries (also derives today) ───────
    // Single range query on `date` — no composite index required.
    _deliveriesSub = _db
        .collection('delivery_records')
        .where('date',
        isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
        .where('date', isLessThan: Timestamp.fromDate(endOfMonth))
        .snapshots()
        .listen(
          (snap) {
        double mKg = 0, mRev = 0, mProf = 0;
        double tKg = 0, tRev = 0, tProf = 0;
        for (final d in snap.docs) {
          final r = DeliveryRecordModel.fromMap(d.id, d.data());
          final cost = costPerKg * r.quantityDelivered;
          mKg += r.quantityDelivered;
          mRev += r.amount;
          mProf += r.amount - cost;
          if (!r.date.isBefore(startOfDay) && r.date.isBefore(endOfDay)) {
            tKg += r.quantityDelivered;
            tRev += r.amount;
            tProf += r.amount - cost;
          }
        }
        _monthSaleKg = mKg;
        _monthRevenue = mRev;
        _monthProfit = mProf;
        _todaySaleKg = tKg;
        _todayRevenue = tRev;
        _todayProfit = tProf;
        _afterEmit();
      },
      onError: (e) {
        debugPrint('Deliveries stream error: $e');
        _afterEmit();
      },
    );

    // ── 4. Active subscriptions ─────────────────────────────
    _subsSub = _db
        .collection('subscriptions')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .listen(
          (snap) {
        _activeSubs = snap.docs.length;
        _afterEmit();
      },
      onError: (e) {
        debugPrint('Subscriptions stream error: $e');
        _afterEmit();
      },
    );

    // ── Rebuild at midnight so today's / month's windows roll over ──
    _midnightTimer?.cancel();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    _midnightTimer = Timer(nextMidnight.difference(now), () {
      if (_disposed) return;
      _startListeners();
    });
  }

  void _afterEmit() {
    if (_disposed) return;
    _loadingTimeout?.cancel();
    if (_loading) _loading = false;
    notifyListeners();
  }

  void _stopListeners() {
    _customersSub?.cancel();
    _ordersSub?.cancel();
    _deliveriesSub?.cancel();
    _subsSub?.cancel();
    _midnightTimer?.cancel();
    _customersSub = null;
    _ordersSub = null;
    _deliveriesSub = null;
    _subsSub = null;
    _midnightTimer = null;
  }

  @override
  void dispose() {
    _disposed = true;
    _loadingTimeout?.cancel();
    _stopListeners();
    _listening = false;
    super.dispose();
  }
}