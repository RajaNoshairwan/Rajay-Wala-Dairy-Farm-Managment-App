import 'package:flutter/material.dart';
import '../models/subscription_model.dart';
import '../services/subscription_service.dart';

class SubscriptionViewModel extends ChangeNotifier {
  final SubscriptionService _service = SubscriptionService();
  List<SubscriptionModel> _subs = [];
  bool _loading = false;

  List<SubscriptionModel> get subscriptions => _subs;
  bool get loading => _loading;

  void listenCustomer(String customerId) {
    _loading = true;
    notifyListeners();
    _service.watchCustomerSubs(customerId).listen(
          (list) { _subs = list; _loading = false; notifyListeners(); },
      onError: (e) { debugPrint('Subs: $e'); _loading = false; notifyListeners(); },
    );
  }

  Future<void> create(SubscriptionModel s) => _service.createSubscription(s);
  Future<void> pause(SubscriptionModel s, DateTime from, DateTime to) => _service.pause(s.subscriptionId, from, to);
  Future<void> resume(SubscriptionModel s) => _service.resume(s.subscriptionId);
  Future<void> cancel(SubscriptionModel s) => _service.cancel(s.subscriptionId);
  Future<void> skip(SubscriptionModel s, DateTime date) => _service.skipDate(s.subscriptionId, date, s.skipDates);
  Future<void> changeQty(SubscriptionModel s, DateTime date, double litres) => _service.changeQuantityForDay(s.subscriptionId, date, litres);
}