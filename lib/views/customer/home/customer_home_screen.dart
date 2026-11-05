import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/customer_home_viewmodel.dart';
import '../../customer/products/product_list_screen.dart';
import '../../customer/billing/bill_list_screen.dart';

class CustomerHomeScreen extends StatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  State<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends State<CustomerHomeScreen> {
  final _vm = CustomerHomeViewModel();

  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid != null) _vm.load(uid);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthViewModel>().profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) {
          if (_vm.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () async {
              final uid = context.read<AuthViewModel>().user?.uid;
              if (uid != null) await _vm.load(uid);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Hello, ${profile?.name ?? 'Customer'} 👋',
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                _StatCard(
                  icon: Icons.payments,
                  title: 'Outstanding Balance',
                  value: CurrencyFormatter.format(_vm.outstanding),
                  color: AppColors.unpaid,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatCard(
                        icon: Icons.receipt_long,
                        title: 'Pending Orders',
                        value: '${_vm.pendingOrders}',
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        icon: Icons.autorenew,
                        title: 'Active Subs',
                        value: '${_vm.activeSubs}',
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text('Quick Actions',
                    style: TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                _ActionTile(
                  icon: Icons.local_drink,
                  label: 'Order Milk',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ProductListScreen()),
                  ),
                ),
                _ActionTile(
                  icon: Icons.receipt,
                  label: 'My Bills',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BillListScreen()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(title,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon, color: AppColors.primary),
        title: Text(label),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}