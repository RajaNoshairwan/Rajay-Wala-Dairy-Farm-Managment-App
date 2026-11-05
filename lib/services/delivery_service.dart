import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/delivery_record_model.dart';

class DeliveryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> recordDelivery(DeliveryRecordModel record) =>
      _db.collection('delivery_records').doc(record.recordId).set(record.toMap());

  Future<void> deleteRecord(String recordId) =>
      _db.collection('delivery_records').doc(recordId).delete();

  Future<List<DeliveryRecordModel>> getRecordsForCustomer(String customerId) async {
    final snap = await _db
        .collection('delivery_records')
        .where('customerId', isEqualTo: customerId)
        .get();
    return snap.docs.map((d) => DeliveryRecordModel.fromMap(d.id, d.data())).toList();
  }

  Future<List<DeliveryRecordModel>> getDeliveriesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    final snap = await _db
        .collection('delivery_records')
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('date', isLessThan: Timestamp.fromDate(end))
        .get();
    return snap.docs.map((d) => DeliveryRecordModel.fromMap(d.id, d.data())).toList();
  }

  Future<int> generateDeliveriesForDate(DateTime date) async {
    final start = DateTime(date.year, date.month, date.day);
    final subsSnap = await _db.collection('subscriptions').where('status', isEqualTo: 'active').get();

    int created = 0;
    for (final subDoc in subsSnap.docs) {
      final sub = subDoc.data();
      final startDate = (sub['startDate'] as Timestamp?)?.toDate() ?? start;
      final endDate = (sub['endDate'] as Timestamp?)?.toDate() ?? start;
      if (start.isBefore(startDate) || start.isAfter(endDate)) continue;

      final skipDates = (sub['skipDates'] as List? ?? [])
          .map((t) => (t as Timestamp).toDate()).toList();
      if (skipDates.any((d) => d.year == start.year && d.month == start.month && d.day == start.day)) continue;

      final overrides = (sub['quantityOverrides'] as Map?) ?? {};
      final key = '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
      final qty = (overrides[key] ?? sub['quantityLitres'] ?? 1).toDouble();

      final productDoc = await _db.collection('products').doc(sub['productId']).get();
      final price = (productDoc.data()?['pricePerLitre'] ?? 0).toDouble();

      final recordId = 'DR-$key-${subDoc.id}';
      await _db.collection('delivery_records').doc(recordId).set({
        'customerId': sub['customerId'],
        'subscriptionId': subDoc.id,
        'date': Timestamp.fromDate(start),
        'quantityDelivered': qty,
        'priceAtDelivery': price,
        'amount': qty * price,
        'status': 'delivered',
        'recordedAt': Timestamp.now(),
      });
      created++;
    }
    return created;
  }
}