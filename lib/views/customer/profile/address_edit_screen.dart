import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/user_model.dart';
import '../../../services/location_service.dart';
import '../../../viewmodels/auth_viewmodel.dart';

class AddressEditScreen extends StatefulWidget {
  const AddressEditScreen({super.key});

  @override
  State<AddressEditScreen> createState() => _AddressEditScreenState();
}

class _AddressEditScreenState extends State<AddressEditScreen> {
  late final TextEditingController _address;
  late final TextEditingController _instructions;
  double _lat = 0;
  double _lng = 0;
  bool _saving = false;
  bool _fetching = false;

  @override
  void initState() {
    super.initState();
    final a = context.read<AuthViewModel>().profile?.address;
    _address = TextEditingController(text: a?.fullAddress ?? '');
    _instructions = TextEditingController(text: a?.instructions ?? '');
    _lat = a?.lat ?? 0;
    _lng = a?.lng ?? 0;
  }

  Future<void> _fetchGps() async {
    setState(() => _fetching = true);
    final loc = LocationService();
    final pos = await loc.getCurrentPosition();
    if (pos != null) {
      _lat = pos.latitude;
      _lng = pos.longitude;
      _address.text = await loc.getAddressFromLatLng(_lat, _lng);
    }
    setState(() => _fetching = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Address')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomTextField(
                controller: _address,
                label: 'Delivery Address',
                maxLines: 3),
            const SizedBox(height: 12),
            CustomTextField(
                controller: _instructions,
                label: 'Delivery Instructions',
                maxLines: 2),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _fetching ? null : _fetchGps,
              icon: const Icon(Icons.my_location),
              label: Text(
                  _fetching ? 'Fetching...' : 'Use My GPS Location'),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Save',
              loading: _saving,
              onPressed: () async {
                final uid =
                    context.read<AuthViewModel>().user?.uid;
                if (uid == null) return;
                setState(() => _saving = true);
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(uid)
                    .update({
                  'address': {
                    'fullAddress': _address.text.trim(),
                    'lat': _lat,
                    'lng': _lng,
                    'instructions': _instructions.text.trim(),
                  }
                });
                setState(() => _saving = false);
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}