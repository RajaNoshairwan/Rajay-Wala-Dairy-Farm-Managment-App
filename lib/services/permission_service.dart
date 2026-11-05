import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PermissionService {
  static Future<void> requestInitialPermissions() async {
    await _location();
    await _notifications();
  }

  static Future<void> _location() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return;
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        await Geolocator.openLocationSettings();
      }
    } catch (e) {
      debugPrint('Location permission error: $e');
    }
  }

  static Future<void> _notifications() async {
    try {
      await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
    } catch (e) {
      debugPrint('Notification permission error: $e');
    }
  }
}