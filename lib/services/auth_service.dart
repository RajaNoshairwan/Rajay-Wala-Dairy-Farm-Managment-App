// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
//
// class AuthService {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   Stream<User?> get authStateChanges => _auth.authStateChanges();
//
//   User? get currentUser => _auth.currentUser;
//
//   Future<UserCredential> signInWithEmail(String email, String password) {
//     return _auth.signInWithEmailAndPassword(
//       email: email.trim(),
//       password: password,
//     );
//   }
//
//   Future<UserCredential> signUpWithEmail(
//       String email, String password) async {
//     return _auth.createUserWithEmailAndPassword(
//       email: email.trim(),
//       password: password,
//     );
//   }
//
//   Future<void> signOut() => _auth.signOut();
//
//   /// Reads the role from custom claims OR from the users document.
//   /// If you set custom claims from the Firebase Console, use
//   /// [getIdTokenResult] to read them.
//   Future<String> getUserRole() async {
//     final user = _auth.currentUser;
//     if (user == null) return 'customer';
//
//     // Try custom claims first
//     final tokenResult = await user.getIdTokenResult(true);
//     if (tokenResult.claims?['admin'] == true) return 'admin';
//
//     // Fallback to Firestore
//     final doc = await _db.collection('users').doc(user.uid).get();
//     if (doc.exists) {
//       return (doc.data()?['role'] as String?) ?? 'customer';
//     }
//     return 'customer';
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserCredential> signInWithEmail(String email, String password) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  Future<String> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return 'customer';

    try {
      final tokenResult = await user.getIdTokenResult(true);
      if (tokenResult.claims?['admin'] == true) return 'admin';
    } catch (_) {}

    try {
      final doc = await _db.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return (doc.data()?['role'] as String?) ?? 'customer';
      }
    } catch (_) {}
    return 'customer';
  }
}