// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import '../../core/widgets/custom_button.dart';
// import '../../core/widgets/custom_text_field.dart';
// import '../../viewmodels/auth_viewmodel.dart';
//
// class AdminLoginScreen extends StatefulWidget {
//   const AdminLoginScreen({super.key});
//
//   @override
//   State<AdminLoginScreen> createState() =>
//       _AdminLoginScreenState();
// }
//
// class _AdminLoginScreenState extends State<AdminLoginScreen> {
//   final _email = TextEditingController();
//   final _password = TextEditingController();
//
//   @override
//   Widget build(BuildContext context) {
//     final authVM = context.watch<AuthViewModel>();
//
//     return Scaffold(
//       appBar: AppBar(title: const Text('Admin Login')),
//       body: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           children: [
//             const SizedBox(height: 40),
//             const Icon(Icons.admin_panel_settings,
//                 size: 80, color: Colors.green),
//             const SizedBox(height: 32),
//             CustomTextField(
//               controller: _email,
//               label: 'Admin Email',
//               keyboardType: TextInputType.emailAddress,
//             ),
//             const SizedBox(height: 16),
//             CustomTextField(
//               controller: _password,
//               label: 'Password',
//               obscureText: true,
//             ),
//             const SizedBox(height: 24),
//             CustomButton(
//               label: 'Login as Admin',
//               loading: authVM.loading,
//               onPressed: () async {
//                 final ok = await authVM.signIn(
//                     _email.text, _password.text);
//                 if (!ok && mounted) {
//                   ScaffoldMessenger.of(context).showSnackBar(
//                     SnackBar(
//                         content: Text(
//                             authVM.error ?? 'Login failed')),
//                   );
//                 }
//               },
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../viewmodels/auth_viewmodel.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  Future<void> _login() async {
    final authVM = context.read<AuthViewModel>();
    final ok = await authVM.signIn(_email.text, _password.text);
    if (!mounted) return;

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(authVM.error ?? 'Login failed')),
      );
      return;
    }

    if (!authVM.isAdmin) {
      await authVM.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This account is not an admin')),
      );
      return;
    }

    // ✅ Admin confirmed — pop back to root so app.dart rebuilds
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Login')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            const Icon(Icons.admin_panel_settings,
                size: 80, color: Colors.green),
            const SizedBox(height: 32),
            CustomTextField(
              controller: _email,
              label: 'Admin Email',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: _password,
              label: 'Password',
              obscureText: true,
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Login as Admin',
              loading: authVM.loading,
              onPressed: _login,
            ),
          ],
        ),
      ),
    );
  }
}