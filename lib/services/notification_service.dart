import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> send({
    required String customerId,
    required String title,
    required String body,
  }) async {
    await _db.collection('notifications').add({
      'customerId': customerId,
      'title': title,
      'body': body,
      'read': false,
      'createdAt': Timestamp.now(),
    });
  }

  Future<void> sendToAllCustomers({
    required String title,
    required String body,
  }) async {
    final customers = await _db
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .get();
    final batch = _db.batch();
    for (final c in customers.docs) {
      final ref = _db.collection('notifications').doc();
      batch.set(ref, {
        'customerId': c.id,
        'title': title,
        'body': body,
        'read': false,
        'createdAt': Timestamp.now(),
      });
    }
    await batch.commit();
  }
}