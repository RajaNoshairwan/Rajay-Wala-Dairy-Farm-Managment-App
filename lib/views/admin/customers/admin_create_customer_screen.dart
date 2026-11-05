import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../services/location_service.dart';
import '../../../viewmodels/admin_customer_viewmodel.dart';

class AdminCreateCustomerScreen extends StatefulWidget {
  const AdminCreateCustomerScreen({super.key});
  @override
  State<AdminCreateCustomerScreen> createState() => _State();
}

class _State extends State<AdminCreateCustomerScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _instructions = TextEditingController();
  double _lat = 0, _lng = 0;
  bool _saving = false, _fetching = false;

  Future<void> _fetchGps() async {
    setState(() => _fetching = true);
    try {
      final loc = LocationService();
      final pos = await loc.getCurrentPosition();
      if (pos != null) {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _address.text = await loc.getAddressFromLatLng(_lat, _lng);
      }
    } catch (_) {}
    if (mounted) setState(() => _fetching = false);
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and phone are required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AdminCustomerViewModel>().createCustomer(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        address: _address.text.trim(),
        instructions: _instructions.text.trim(),
        lat: _lat,
        lng: _lng,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New Customer')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          CustomTextField(controller: _name, label: 'Full Name'),
          const SizedBox(height: 12),
          CustomTextField(controller: _phone, label: 'Phone Number', keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          CustomTextField(controller: _email, label: 'Email (optional)', keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 12),
          CustomTextField(controller: _address, label: 'Delivery Address', maxLines: 2),
          const SizedBox(height: 12),
          CustomTextField(controller: _instructions, label: 'Delivery Instructions', maxLines: 2),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _fetching ? null : _fetchGps,
            icon: const Icon(Icons.my_location),
            label: Text(_fetching ? 'Fetching...' : 'Use GPS Location'),
          ),
          const SizedBox(height: 24),
          CustomButton(label: 'Create Customer', loading: _saving, onPressed: _save),
        ]),
      ),
    );
  }
}