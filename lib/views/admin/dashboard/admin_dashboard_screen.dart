import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../viewmodels/admin_dashboard_viewmodel.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});
  @override
  State<AdminDashboardScreen> createState() => _State();
}

class _State extends State<AdminDashboardScreen> {
  @override
  void initState() { super.initState(); context.read<AdminDashboardViewModel>().load(); }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminDashboardViewModel>();
    return vm.loading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
      onRefresh: vm.load,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        const Text('Overview', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.4,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _Tile('Total Customers', '${vm.totalCustomers}', Icons.people, Colors.blue),
            _Tile("Today's Orders", '${vm.todayOrders}', Icons.receipt_long, Colors.orange),
            _Tile('Monthly Revenue', CurrencyFormatter.format(vm.monthlyRevenue), Icons.trending_up, AppColors.success),
            _Tile('Pending Payments', CurrencyFormatter.format(vm.pendingPayments), Icons.warning_amber, AppColors.error),
          ],
        ),
        const SizedBox(height: 12),
        Card(
          color: AppColors.primary,
          child: ListTile(
            leading: const Icon(Icons.autorenew, color: Colors.white, size: 32),
            title: const Text('Active Subscriptions', style: TextStyle(color: Colors.white70, fontSize: 13)),
            subtitle: Text('${vm.activeSubs} active subscriptions',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          ),
        ),
      ]),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color color;
  const _Tile(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8)]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 28),
        const Spacer(),
        Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}