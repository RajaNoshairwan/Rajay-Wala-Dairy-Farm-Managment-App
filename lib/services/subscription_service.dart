import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subscription_model.dart';

class SubscriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> createSubscription(SubscriptionModel s) async {
    final ref = await _db.collection('subscriptions').add(s.toMap());
    return ref.id;
  }

  Stream<List<SubscriptionModel>> watchCustomerSubs(String customerId) {
    return _db
        .collection('subscriptions')
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((s) {
      final list = s.docs.map((d) => SubscriptionModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    });
  }

  Stream<List<SubscriptionModel>> watchAllSubs() {
    return _db.collection('subscriptions').snapshots().map((s) {
      final list = s.docs.map((d) => SubscriptionModel.fromMap(d.id, d.data())).toList();
      list.sort((a, b) => b.startDate.compareTo(a.startDate));
      return list;
    });
  }

  Future<void> pause(String id, DateTime from, DateTime to) =>
      _db.collection('subscriptions').doc(id).update({
        'isPaused': true, 'status': 'paused',
        'pausedFrom': Timestamp.fromDate(from),
        'pausedTo': Timestamp.fromDate(to),
      });

  Future<void> resume(String id) =>
      _db.collection('subscriptions').doc(id).update({
        'isPaused': false, 'status': 'active',
        'pausedFrom': null, 'pausedTo': null,
      });

  Future<void> cancel(String id) =>
      _db.collection('subscriptions').doc(id).update({'status': 'cancelled'});

  Future<void> skipDate(String id, DateTime date, List<DateTime> existing) {
    final updated = [...existing.map((d) => Timestamp.fromDate(d)), Timestamp.fromDate(date)];
    return _db.collection('subscriptions').doc(id).update({'skipDates': updated});
  }

  Future<void> changeQuantityForDay(String id, DateTime date, double litres) {
    final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return _db.collection('subscriptions').doc(id).update({'quantityOverrides.$key': litres});
  }
}