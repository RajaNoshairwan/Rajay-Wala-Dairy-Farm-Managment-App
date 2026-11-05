import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/billing_viewmodel.dart';
import '../billing/payment_history_screen.dart';
import '../subscriptions/subscription_list_screen.dart';
import 'address_edit_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authVM = context.watch<AuthViewModel>();
    final profile = authVM.profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profile == null
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary,
            child: Text(
              profile.name.isNotEmpty
                  ? profile.name[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                  fontSize: 32, color: Colors.white),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(profile.name,
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
          ),
          Center(
            child: Text(profile.phone,
                style: const TextStyle(
                    color: AppColors.textSecondary)),
          ),
          Center(
            child: Text(profile.email,
                style: const TextStyle(
                    color: AppColors.textSecondary)),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.location_on),
            title: const Text('Delivery Address'),
            subtitle: Text(profile.address.fullAddress),
            trailing: const Icon(Icons.edit),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const AddressEditScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.autorenew),
            title: const Text('My Subscriptions'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                  const SubscriptionListScreen()),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.payments),
            title: const Text('Payment History'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              final uid = context.read<AuthViewModel>().user?.uid;
              if (uid != null) {
                context
                    .read<BillingViewModel>()
                    .loadCustomerBilling(uid);
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                    const PaymentHistoryScreen()),
              );
            },
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () => authVM.signOut(),
            icon: const Icon(Icons.logout,
                color: AppColors.error),
            label: const Text('Logout',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}