// // import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart';
// // import '../services/auth_service.dart';
// // import '../models/user_model.dart';
// // import 'package:cloud_firestore/cloud_firestore.dart';
// //
// // class AuthViewModel extends ChangeNotifier {
// //   final AuthService _authService = AuthService();
// //   final FirebaseFirestore _db = FirebaseFirestore.instance;
// //
// //   User? _user;
// //   UserModel? _profile;
// //   bool _loading = false;
// //   String? _error;
// //   bool _isAdmin = false;
// //
// //   User? get user => _user;
// //   UserModel? get profile => _profile;
// //   bool get loading => _loading;
// //   String? get error => _error;
// //   bool get isAdmin => _isAdmin;
// //
// //   AuthViewModel() {
// //     _authService.authStateChanges.listen((user) async {
// //       _user = user;
// //       if (user != null) {
// //         await _loadProfile(user.uid);
// //         _isAdmin = await _authService.getUserRole() == 'admin';
// //       } else {
// //         _profile = null;
// //         _isAdmin = false;
// //       }
// //       notifyListeners();
// //     });
// //   }
// //
// //   Future<void> _loadProfile(String uid) async {
// //     final doc = await _db.collection('users').doc(uid).get();
// //     if (doc.exists) {
// //       _profile = UserModel.fromMap(uid, doc.data()!);
// //     }
// //   }
// //
// //   Future<bool> signIn(String email, String password) async {
// //     _loading = true;
// //     _error = null;
// //     notifyListeners();
// //     try {
// //       await _authService.signInWithEmail(email, password);
// //       _loading = false;
// //       notifyListeners();
// //       return true;
// //     } on FirebaseAuthException catch (e) {
// //       _error = e.message;
// //       _loading = false;
// //       notifyListeners();
// //       return false;
// //     }
// //   }
// //
// //   Future<bool> signUp({
// //     required String email,
// //     required String password,
// //     required String name,
// //     required String phone,
// //     required DeliveryAddress address,
// //   }) async {
// //     _loading = true;
// //     _error = null;
// //     notifyListeners();
// //     try {
// //       final cred =
// //       await _authService.signUpWithEmail(email, password);
// //       final uid = cred.user!.uid;
// //       final userModel = UserModel(
// //         uid: uid,
// //         role: 'customer',
// //         name: name,
// //         phone: phone,
// //         email: email,
// //         address: address,
// //         createdAt: DateTime.now(),
// //       );
// //       await _db
// //           .collection('users')
// //           .doc(uid)
// //           .set(userModel.toMap());
// //       _loading = false;
// //       notifyListeners();
// //       return true;
// //     } on FirebaseAuthException catch (e) {
// //       _error = e.message;
// //       _loading = false;
// //       notifyListeners();
// //       return false;
// //     }
// //   }
// //
// //   Future<void> signOut() async {
// //     await _authService.signOut();
// //     _isAdmin = false;
// //   }
// // }
//
//
//
// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/auth_service.dart';
// import '../models/user_model.dart';
//
// class AuthViewModel extends ChangeNotifier {
//   final AuthService _authService = AuthService();
//   final FirebaseFirestore _db = FirebaseFirestore.instance;
//
//   User? _user;
//   UserModel? _profile;
//   bool _loading = false;
//   String? _error;
//   bool _isAdmin = false;
//
//   User? get user => _user;
//   UserModel? get profile => _profile;
//   bool get loading => _loading;
//   String? get error => _error;
//   bool get isAdmin => _isAdmin;
//
//   AuthViewModel() {
//     _authService.authStateChanges.listen((user) async {
//       _user = user;
//       if (user != null) {
//         await _refreshProfileAndRole(user.uid);
//       } else {
//         _profile = null;
//         _isAdmin = false;
//       }
//       notifyListeners();
//     });
//   }
//
//   Future<void> _refreshProfileAndRole(String uid) async {
//     try {
//       final doc = await _db.collection('users').doc(uid).get();
//       if (doc.exists) {
//         _profile = UserModel.fromMap(uid, doc.data()!);
//       }
//     } catch (e) {
//       debugPrint('Load profile error: $e');
//     }
//     try {
//       _isAdmin = await _authService.getUserRole() == 'admin';
//     } catch (e) {
//       debugPrint('Load role error: $e');
//       _isAdmin = false;
//     }
//   }
//
//   Future<void> reloadProfile() async {
//     final uid = _user?.uid;
//     if (uid == null) return;
//     await _refreshProfileAndRole(uid);
//     notifyListeners();
//   }
//
//   Future<bool> signIn(String email, String password) async {
//     _loading = true;
//     _error = null;
//     notifyListeners();
//     try {
//       final cred = await _authService.signInWithEmail(email, password);
//       _user = cred.user;
//       await _refreshProfileAndRole(cred.user!.uid);
//       _loading = false;
//       notifyListeners();
//       return true;
//     } on FirebaseAuthException catch (e) {
//       _error = e.message ?? 'Login failed';
//       _loading = false;
//       notifyListeners();
//       return false;
//     } catch (e) {
//       _error = e.toString();
//       _loading = false;
//       notifyListeners();
//       return false;
//     }
//   }
//
//   Future<bool> signUp({
//     required String email,
//     required String password,
//     required String name,
//     required String phone,
//     required DeliveryAddress address,
//   }) async {
//     _loading = true;
//     _error = null;
//     notifyListeners();
//     try {
//       final cred = await _authService.signUpWithEmail(email, password);
//       final uid = cred.user!.uid;
//       final userModel = UserModel(
//         uid: uid,
//         role: 'customer',
//         name: name,
//         phone: phone,
//         email: email,
//         address: address,
//         createdAt: DateTime.now(),
//       );
//       await _db.collection('users').doc(uid).set(userModel.toMap());
//       _profile = userModel;
//       _isAdmin = false;
//       _user = cred.user;
//       _loading = false;
//       notifyListeners();
//       return true;
//     } on FirebaseAuthException catch (e) {
//       _error = e.message ?? 'Signup failed';
//       _loading = false;
//       notifyListeners();
//       return false;
//     } catch (e) {
//       // Firestore write failed — clean up orphan Auth user
//       try {
//         await _authService.signOut();
//       } catch (_) {}
//       _user = null;
//       _profile = null;
//       _isAdmin = false;
//       _error = 'Account created but profile save failed: $e';
//       _loading = false;
//       notifyListeners();
//       return false;
//     }
//   }
//
//   Future<void> signOut() async {
//     try {
//       await _authService.signOut();
//     } catch (e) {
//       debugPrint('Signout error: $e');
//     }
//     _user = null;
//     _profile = null;
//     _isAdmin = false;
//     notifyListeners();
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─────────────────────────────────────────────────────────────
  // State
  // ─────────────────────────────────────────────────────────────
  User? _user;
  UserModel? _profile;
  bool _loading = false;
  String? _error;
  bool _isAdmin = false;

  /// True once Firebase Auth has emitted its first state (either a
  /// restored session or `null`). The root widget uses this to
  /// avoid flashing the login screen on app restart.
  bool _initialized = false;

  // ─────────────────────────────────────────────────────────────
  // Getters
  // ─────────────────────────────────────────────────────────────
  User? get user => _user;
  UserModel? get profile => _profile;
  bool get loading => _loading;
  String? get error => _error;
  bool get isAdmin => _isAdmin;
  bool get initialized => _initialized;

  // ─────────────────────────────────────────────────────────────
  // Constructor — listen to Firebase Auth state
  // ─────────────────────────────────────────────────────────────
  AuthViewModel() {
    _authService.authStateChanges.listen(
          (user) async {
        _user = user;
        if (user != null) {
          await _refreshProfileAndRole(user.uid);
        } else {
          _profile = null;
          _isAdmin = false;
        }
        _initialized = true;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Auth state stream error: $e');
        _initialized = true;
        notifyListeners();
      },
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────

  /// Loads both the Firestore profile AND the role, catching
  /// each step separately so a failure in one doesn't break the other.
  Future<void> _refreshProfileAndRole(String uid) async {
    try {
      final doc = await _db.collection('users').doc(uid).get();
      if (doc.exists) {
        _profile = UserModel.fromMap(uid, doc.data()!);
      }
    } catch (e) {
      debugPrint('Load profile error: $e');
    }

    try {
      _isAdmin = await _authService.getUserRole() == 'admin';
    } catch (e) {
      debugPrint('Load role error: $e');
      _isAdmin = false;
    }
  }

  /// Manually reload the profile — call this after the customer
  /// edits their address or after an admin changes a customer record.
  Future<void> reloadProfile() async {
    final uid = _user?.uid;
    if (uid == null) return;
    await _refreshProfileAndRole(uid);
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Sign In
  // ─────────────────────────────────────────────────────────────
  Future<bool> signIn(String email, String password) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _authService.signInWithEmail(email, password);
      _user = cred.user;
      await _refreshProfileAndRole(cred.user!.uid);
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Login failed';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Sign Up
  // ─────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
    required DeliveryAddress address,
  }) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final cred = await _authService.signUpWithEmail(email, password);
      final uid = cred.user!.uid;

      final userModel = UserModel(
        uid: uid,
        role: 'customer',
        name: name,
        phone: phone,
        email: email,
        address: address,
        createdAt: DateTime.now(),
      );

      await _db.collection('users').doc(uid).set(userModel.toMap());

      _profile = userModel;
      _isAdmin = false;
      _user = cred.user;
      _loading = false;
      notifyListeners();
      return true;
    } on FirebaseAuthException catch (e) {
      _error = e.message ?? 'Signup failed';
      _loading = false;
      notifyListeners();
      return false;
    } catch (e) {
      // Firestore write failed — clean up the orphan Auth user so
      // the app doesn't get stuck in a half-registered state.
      try {
        await _authService.signOut();
      } catch (_) {}

      _user = null;
      _profile = null;
      _isAdmin = false;
      _error = 'Account created but profile save failed: $e';
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Sign Out
  // ─────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    try {
      await _authService.signOut();
    } catch (e) {
      debugPrint('Signout error: $e');
    }
    _user = null;
    _profile = null;
    _isAdmin = false;
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // Clear error (optional helper for UI)
  // ─────────────────────────────────────────────────────────────
  void clearError() {
    _error = null;
    notifyListeners();
  }
}