import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../core/widgets/custom_button.dart';
import '../../viewmodels/auth_viewmodel.dart';
import 'signup_screen.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              Icon(Icons.local_drink,
                  size: 80, color: AppColors.primary),
              const SizedBox(height: 12),
              Text('Milk Delivery',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  )),
              const SizedBox(height: 40),
              CustomTextField(
                controller: _email,
                label: 'Email',
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
              ),
              const SizedBox(height: 16),
              CustomTextField(
                controller: _password,
                label: 'Password',
                obscureText: true,
                prefixIcon: Icons.lock_outline,
              ),
              if (authVM.error != null) ...[
                const SizedBox(height: 8),
                Text(authVM.error!,
                    style:
                    const TextStyle(color: AppColors.error)),
              ],
              const SizedBox(height: 24),
              CustomButton(
                label: 'Login',
                loading: authVM.loading,
                onPressed: () async {
                  await authVM.signIn(
                      _email.text, _password.text);
                },
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const SignupScreen()),
                  );
                },
                child: const Text(
                    "Don't have an account? Sign up"),
              ),
              const Divider(height: 40),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                        const AdminLoginScreen()),
                  );
                },
                icon: const Icon(Icons.admin_panel_settings),
                label: const Text('Admin Login'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  foregroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}