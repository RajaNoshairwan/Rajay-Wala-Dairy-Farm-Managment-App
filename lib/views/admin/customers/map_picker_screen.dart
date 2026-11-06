import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/constants/app_colors.dart';
import '../../../services/location_service.dart';
import '../../../services/permission_service.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;
  final String? initialAddress;

  const MapPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
    this.initialAddress,
  });

  @override
  State<MapPickerScreen> createState() => _State();
}

class _State extends State<MapPickerScreen> {
  final _mapController = MapController();
  final _addressCtrl = TextEditingController();

  // Default fallback center — Lahore
  LatLng _center = const LatLng(31.5204, 74.3587);
  bool _loadingLocation = false;
  bool _loadingAddress = false;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _addressCtrl.text = widget.initialAddress ?? '';
    if (widget.initialLat != null &&
        widget.initialLng != null &&
        !(widget.initialLat == 0 && widget.initialLng == 0)) {
      _center = LatLng(widget.initialLat!, widget.initialLng!);
      _ready = true;
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _goToCurrent());
    }
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _goToCurrent() async {
    setState(() => _loadingLocation = true);

    final ready = await PermissionService.ensureLocationReady(context);
    if (!ready) {
      if (mounted) {
        setState(() {
          _loadingLocation = false;
          _ready = true;
        });
      }
      return;
    }

    try {
      final loc = LocationService();
      final pos = await loc.getCurrentPosition();
      if (pos != null) {
        final newPos = LatLng(pos.latitude, pos.longitude);
        setState(() => _center = newPos);
        _mapController.move(newPos, 16);
        await _refreshAddress(newPos);
      }
    } catch (e) {
      debugPrint('Current location error: $e');
    }
    if (mounted) {
      setState(() {
        _loadingLocation = false;
        _ready = true;
      });
    }
  }

  Future<void> _refreshAddress(LatLng pos) async {
    setState(() => _loadingAddress = true);
    try {
      final loc = LocationService();
      final addr =
      await loc.getAddressFromLatLng(pos.latitude, pos.longitude);
      if (mounted && addr.isNotEmpty) {
        _addressCtrl.text = addr;
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
    if (mounted) setState(() => _loadingAddress = false);
  }

  void _confirm() {
    final addr = _addressCtrl.text.trim();
    if (addr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an address')),
      );
      return;
    }
    Navigator.pop(context, {
      'lat': _center.latitude,
      'lng': _center.longitude,
      'address': addr,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            tooltip: 'Use current location',
            icon: _loadingLocation
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
                : const Icon(Icons.my_location),
            onPressed: _loadingLocation ? null : _goToCurrent,
          ),
        ],
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          // ── Map ─────────────────────────────────────
          Positioned.fill(
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _center,
                initialZoom: 16,
                minZoom: 3,
                maxZoom: 19,
                // Live update as user pans
                onPositionChanged: (camera, hasGesture) {
                  if (hasGesture) {
                    setState(() => _center = camera.center);
                  }
                },
                // Tap to move pin
                onTap: (_, point) {
                  setState(() => _center = point);
                  _mapController.move(point, _mapController.camera.zoom);
                  _refreshAddress(point);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName:
                  'com.example.rajay_wala_dairy',
                  maxNativeZoom: 19,
                ),
                // Pin at the current center
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _center,
                      width: 44,
                      height: 44,
                      alignment: Alignment.topCenter,
                      child: const Icon(
                        Icons.location_pin,
                        size: 44,
                        color: Colors.red,
                        shadows: [
                          Shadow(
                              color: Colors.black38,
                              blurRadius: 4,
                              offset: Offset(0, 2)),
                        ],
                      ),
                    ),
                  ],
                ),
                // OSM attribution (required by their terms)
                const RichAttributionWidget(
                  attributions: [
                    TextSourceAttribution(
                      'OpenStreetMap contributors',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Center crosshair (visual guide) ─────────
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 24),
                child: Icon(
                  Icons.add,
                  size: 20,
                  color: Colors.black45,
                ),
              ),
            ),
          ),

          // ── Hint banner ─────────────────────────────
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app,
                        size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Pan the map or tap to move the pin',
                        style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom sheet ────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Card(
              margin: EdgeInsets.zero,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular(20)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  MediaQuery.of(context).padding.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        labelText: 'Address',
                        prefixIcon: const Icon(Icons.location_on),
                        suffixIcon: _loadingAddress
                            ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child:
                            CircularProgressIndicator(
                                strokeWidth: 2),
                          ),
                        )
                            : null,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.my_location,
                            size: 12,
                            color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${_center.latitude.toStringAsFixed(5)}, '
                              '${_center.longitude.toStringAsFixed(5)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _confirm,
                      icon: const Icon(Icons.check),
                      label: const Text('Save Location'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding:
                        const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}