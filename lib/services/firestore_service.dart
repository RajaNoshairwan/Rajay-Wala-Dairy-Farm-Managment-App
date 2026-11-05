import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> collection(String path) {
    return _db.collection(path);
  }

  Future<DocumentReference<Map<String, dynamic>>> add(
      String path, Map<String, dynamic> data) {
    return _db.collection(path).add(data);
  }

  Future<void> set(
      String path, String docId, Map<String, dynamic> data) {
    return _db.collection(path).doc(docId).set(data);
  }

  Future<void> update(
      String path, String docId, Map<String, dynamic> data) {
    return _db.collection(path).doc(docId).update(data);
  }

  Future<void> delete(String path, String docId) {
    return _db.collection(path).doc(docId).delete();
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> get(
      String path, String docId) {
    return _db.collection(path).doc(docId).get();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> stream(
      String path, {Query? query}) {
    return _db.collection(path).snapshots();
  }

  Future<QuerySnapshot<Map<String, dynamic>>> query(
      String path, {
        String? field,
        dynamic isEqualTo,
        String? orderBy,
        bool descending = false,
        int? limit,
      }) {
    Query<Map<String, dynamic>> q = _db.collection(path);
    if (field != null && isEqualTo != null) {
      q = q.where(field, isEqualTo: isEqualTo);
    }
    if (orderBy != null) {
      q = q.orderBy(orderBy, descending: descending);
    }
    if (limit != null) q = q.limit(limit);
    return q.get();
  }
}