import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class CustomerService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<UserModel>> watchAllCustomers() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .snapshots()
        .map((s) {
      final list =
      s.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList();
      list.sort(
              (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return list;
    });
  }

  Future<List<UserModel>> getAllCustomers() async {
    final snap = await _db
        .collection('users')
        .where('role', isEqualTo: 'customer')
        .get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<UserModel?> getCustomer(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(uid, doc.data()!);
  }

  Future<String> createCustomer(UserModel user) async {
    final ref = _db.collection('users').doc();
    final map = user.toMap();
    map['uid'] = ref.id;
    map['createdByAdmin'] = true;
    await ref.set(map);
    return ref.id;
  }

  Future<void> updateCustomer(String uid, Map<String, dynamic> data) =>
      _db.collection('users').doc(uid).update(data);

  Future<void> blockCustomer(String uid, bool blocked) =>
      _db.collection('users').doc(uid).update({'isBlocked': blocked});
}