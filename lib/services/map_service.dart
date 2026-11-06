import 'package:url_launcher/url_launcher.dart';

class MapService {
  /// Opens Google Maps centered on the location.
  static Future<void> viewLocation(double lat, double lng) async {
    if (lat == 0 && lng == 0) return;
    await _launch(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
  }

  /// Opens Google Maps directions from current position to destination.
  static Future<void> getDirections(double lat, double lng) async {
    if (lat == 0 && lng == 0) return;
    await _launch(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );
  }

  static Future<void> _launch(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } catch (e) {
        // ignore: avoid_print
        print('Launch URL failed: $e');
      }
    }
  }
}