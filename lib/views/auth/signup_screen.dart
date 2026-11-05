import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../models/user_model.dart';
import '../../services/location_service.dart';
import '../../viewmodels/auth_viewmodel.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _address = TextEditingController();
  final _instructions = TextEditingController();
  double _lat = 0;
  double _lng = 0;
  bool _fetching = false;

  Future<void> _fetchGps() async {
    setState(() => _fetching = true);
    final loc = LocationService();
    final pos = await loc.getCurrentPosition();
    if (pos != null) {
      _lat = pos.latitude;
      _lng = pos.longitude;
      final addr = await loc.getAddressFromLatLng(_lat, _lng);
      _address.text = addr;
    }
    setState(() => _fetching = false);
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                CustomTextField(
                    controller: _name,
                    label: 'Full Name',
                    validator: (v) => Validators.required(v, 'Name')),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: _phone,
                    label: 'Phone Number',
                    keyboardType: TextInputType.phone,
                    validator: (v) => Validators.required(v, 'Phone')),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: Validators.email),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: _password,
                    label: 'Password',
                    obscureText: true,
                    validator: Validators.password),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _confirm,
                  label: 'Confirm Password',
                  obscureText: true,
                  validator: (v) {
                    if (v != _password.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: _address,
                    label: 'Delivery Address',
                    maxLines: 2,
                    validator: (v) => Validators.required(v, 'Address')),
                const SizedBox(height: 12),
                CustomTextField(
                    controller: _instructions,
                    label: 'Delivery Instructions (optional)',
                    maxLines: 2),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _fetching ? null : _fetchGps,
                  icon: const Icon(Icons.my_location),
                  label: Text(_fetching
                      ? 'Fetching...'
                      : 'Use My GPS Location'),
                ),
                const SizedBox(height: 24),
                if (authVM.error != null)
                  Text(authVM.error!,
                      style: const TextStyle(color: AppColors.error)),
                CustomButton(
                  label: 'Sign Up',
                  loading: authVM.loading,
                  onPressed: () async {
                    if (!_formKey.currentState!.validate()) return;
                    final ok = await authVM.signUp(
                      email: _email.text.trim(),
                      password: _password.text,
                      name: _name.text.trim(),
                      phone: _phone.text.trim(),
                      address: DeliveryAddress(
                        fullAddress: _address.text.trim(),
                        lat: _lat,
                        lng: _lng,
                        instructions: _instructions.text.trim(),
                      ),
                    );
                    if (!mounted) return;
                    if (ok) {
                      Navigator.pop(context);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(authVM.error ?? 'Signup failed')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}