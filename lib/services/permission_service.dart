import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class PermissionService {
  /// Called once at app start (from main.dart).
  /// Requests location permission, opens location settings if device
  /// location is OFF, and requests notification permission.
  static Future<void> requestInitialPermissions() async {
    await _requestLocationOnLaunch();
    await _requestNotifications();
  }

  static Future<void> _requestLocationOnLaunch() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      // Only if permission granted, check whether device location is on
      if (perm == LocationPermission.whileInUse ||
          perm == LocationPermission.always) {
        final enabled = await Geolocator.isLocationServiceEnabled();
        if (!enabled) {
          await Geolocator.openLocationSettings();
        }
      }
    } catch (e) {
      debugPrint('Initial location permission error: $e');
    }
  }

  static Future<void> _requestNotifications() async {
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

  /// Call this before any action that needs the current position
  /// (e.g. MapPicker "Use current location").
  ///
  /// Flow:
  ///   1. Request permission if not yet decided.
  ///   2. If permission was permanently denied, open app settings.
  ///   3. If device location is OFF, show dialog → open location settings.
  ///   4. Return true only when both permission + service are ON.
  static Future<bool> ensureLocationReady(BuildContext context) async {
    // ── 1. Permission ─────────────────────────────────────
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    if (perm == LocationPermission.deniedForever) {
      if (context.mounted) {
        final go = await _confirm(
          context,
          title: 'Location permission blocked',
          message:
          'Location access is permanently blocked. Open app settings to allow it.',
          buttonText: 'Open App Settings',
        );
        if (go == true) await Geolocator.openAppSettings();
      }
      return false;
    }
    if (perm == LocationPermission.denied) {
      if (context.mounted) {
        final go = await _confirm(
          context,
          title: 'Location permission needed',
          message:
          'We need location access to show your current position and get directions.',
          buttonText: 'Allow',
        );
        if (go == true) {
          perm = await Geolocator.requestPermission();
        }
      }
      if (perm != LocationPermission.whileInUse &&
          perm != LocationPermission.always) {
        return false;
      }
    }

    // ── 2. Device location service ────────────────────────
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (context.mounted) {
        final go = await _confirm(
          context,
          title: 'Location is off',
          message:
          'Turn on device location so we can show your current position and provide directions.',
          buttonText: 'Open Location Settings',
        );
        if (go == true) {
          await Geolocator.openLocationSettings();
          // Give the user a moment to toggle it, then re-check
          await Future.delayed(const Duration(seconds: 1));
          return await Geolocator.isLocationServiceEnabled();
        }
      }
      return false;
    }

    return true;
  }

  static Future<bool?> _confirm(
      BuildContext context, {
        required String title,
        required String message,
        required String buttonText,
      }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }
}