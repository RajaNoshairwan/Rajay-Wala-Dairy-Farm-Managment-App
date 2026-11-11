import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../viewmodels/admin_customer_viewmodel.dart';
import 'map_picker_screen.dart';

class AdminCreateCustomerScreen extends StatefulWidget {
  const AdminCreateCustomerScreen({super.key});
  @override
  State<AdminCreateCustomerScreen> createState() => _State();
}

class _State extends State<AdminCreateCustomerScreen> {
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  final _phone = TextEditingController();
  final _emergency = TextEditingController();
  final _rate = TextEditingController(text: '0');
  final _address = TextEditingController();
  final _instructions = TextEditingController();
  double _lat = 0.0, _lng = 0.0;
  bool _saving = false;

  Future<void> _pickLocation() async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder: (_) => MapPickerScreen(
          initialLat: _lat == 0 ? null : _lat,
          initialLng: _lng == 0 ? null : _lng,
          initialAddress:
          _address.text.trim().isEmpty ? null : _address.text.trim(),
        ),
      ),
    );
    if (result != null && mounted) {
      setState(() {
        _lat = (result['lat'] as num).toDouble();
        _lng = (result['lng'] as num).toDouble();
        _address.text = result['address'] as String;
      });
    }
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Name and phone are required')));
      return;
    }
    setState(() => _saving = true);
    try {
      await context.read<AdminCustomerViewModel>().createCustomer(
        name: _name.text.trim(),
        nickname: _nickname.text.trim(),
        phone: _phone.text.trim(),
        emergencyContact: _emergency.text.trim(),
        ratePerKg: double.tryParse(_rate.text) ?? 0.0,
        address: _address.text.trim(),
        instructions: _instructions.text.trim(),
        lat: _lat,
        lng: _lng,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
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
          CustomTextField(
              controller: _nickname,
              label: 'Nickname (for spreadsheet)'),
          const SizedBox(height: 12),
          CustomTextField(
              controller: _phone,
              label: 'Phone Number',
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          CustomTextField(
              controller: _emergency,
              label: 'Emergency Contact',
              keyboardType: TextInputType.phone),
          const SizedBox(height: 12),
          CustomTextField(
              controller: _rate,
              label: 'Rate per kg (Rs)',
              keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          CustomTextField(
              controller: _address, label: 'Delivery Address', maxLines: 2),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickLocation,
              icon: const Icon(Icons.map),
              label: Text(_lat == 0 && _lng == 0
                  ? 'Pick Location on Map'
                  : 'Change Location on Map'),
            ),
          ),
          if (_lat != 0 || _lng != 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.pin_drop,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 4),
                Text(
                  '${_lat.toStringAsFixed(5)}, ${_lng.toStringAsFixed(5)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ],
          const SizedBox(height: 12),
          CustomTextField(
              controller: _instructions,
              label: 'Delivery Instructions',
              maxLines: 2),
          const SizedBox(height: 24),
          CustomButton(
              label: 'Create Customer',
              loading: _saving,
              onPressed: _save),
        ]),
      ),
    );
  }
}