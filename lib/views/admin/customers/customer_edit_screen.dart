import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/user_model.dart';
import '../../../viewmodels/admin_customer_viewmodel.dart';
import 'map_picker_screen.dart';

class CustomerEditScreen extends StatefulWidget {
  final UserModel customer;
  const CustomerEditScreen({super.key, required this.customer});
  @override
  State<CustomerEditScreen> createState() => _State();
}

class _State extends State<CustomerEditScreen> {
  late final TextEditingController _name;
  late final TextEditingController _nickname;
  late final TextEditingController _phone;
  late final TextEditingController _emergency;
  late final TextEditingController _rate;
  late final TextEditingController _address;
  late final TextEditingController _instructions;
  late double _lat;
  late double _lng;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c.name);
    _nickname = TextEditingController(text: c.nickname);
    _phone = TextEditingController(text: c.phone);
    _emergency = TextEditingController(text: c.emergencyContact);
    _rate = TextEditingController(text: c.ratePerKg.toStringAsFixed(0));
    _address = TextEditingController(text: c.address.fullAddress);
    _instructions = TextEditingController(text: c.address.instructions);
    _lat = c.address.lat;
    _lng = c.address.lng;
  }

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
    setState(() => _saving = true);
    try {
      await context.read<AdminCustomerViewModel>().updateCustomer(
        widget.customer.uid,
        {
          'name': _name.text.trim(),
          'nickname': _nickname.text.trim(),
          'phone': _phone.text.trim(),
          'emergencyContact': _emergency.text.trim(),
          'ratePerKg': double.tryParse(_rate.text) ?? 0.0,
          'address': {
            'fullAddress': _address.text.trim(),
            'lat': _lat,
            'lng': _lng,
            'instructions': _instructions.text.trim(),
          },
        },
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
      appBar: AppBar(title: const Text('Edit Customer')),
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
              label: 'Save Changes',
              loading: _saving,
              onPressed: _save),
        ]),
      ),
    );
  }
}