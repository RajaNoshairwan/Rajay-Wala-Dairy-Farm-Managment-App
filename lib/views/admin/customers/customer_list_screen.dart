import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../viewmodels/admin_customer_viewmodel.dart';
import 'admin_create_customer_screen.dart';
import 'customer_detail_screen.dart';
import 'dead_customers_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});
  @override
  State<CustomerListScreen> createState() => _State();
}

class _State extends State<CustomerListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<AdminCustomerViewModel>().listen();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminCustomerViewModel>();
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => const AdminCreateCustomerScreen()),
        ),
        icon: const Icon(Icons.person_add),
        label: const Text('New Customer'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search row + Dead Customers button
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding:
                      const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onChanged: vm.search,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Dead Customers',
                  icon: const Icon(Icons.person_off),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const DeadCustomersScreen()),
                  ),
                ),
              ],
            ),
          ),
          // Live count summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text('${vm.customers.length} live',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                Text('· ${vm.deadCustomers.length} dead',
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: vm.loading
                ? const Center(child: CircularProgressIndicator())
                : vm.customers.isEmpty
                ? const EmptyState(
                message: 'No live customers',
                icon: Icons.people_outline)
                : ListView.builder(
              padding:
              const EdgeInsets.fromLTRB(12, 4, 12, 80),
              itemCount: vm.customers.length,
              itemBuilder: (context, i) {
                final c = vm.customers[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: c.isBlocked
                          ? Colors.red.shade200
                          : Colors.green.shade200,
                      child: Text(c.name.isNotEmpty
                          ? c.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(c.name),
                    subtitle: Text(
                        '${c.phone} · Owed: ${CurrencyFormatter.format(c.outstandingBalance)}'),
                    trailing:
                    const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CustomerDetailScreen(customer: c),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}