import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/user_model.dart';
import '../../../viewmodels/admin_customer_viewmodel.dart';

class DeadCustomersScreen extends StatelessWidget {
  const DeadCustomersScreen({super.key});

  Future<void> _restore(
      BuildContext context, UserModel customer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore Customer'),
        content: Text(
            'Move "${customer.name}" back to Live customers?\n\nThey will reappear in lists, spreadsheet and billing.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    await context
        .read<AdminCustomerViewModel>()
        .markDead(customer, false);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${customer.name} restored to Live'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminCustomerViewModel>();
    final dead = vm.deadCustomers;

    return Scaffold(
      appBar: AppBar(title: const Text('Dead Customers')),
      body: dead.isEmpty
          ? const EmptyState(
          message: 'No dead customers',
          icon: Icons.person_off_outlined)
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: dead.length,
        itemBuilder: (context, i) {
          final c = dead[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: Text(c.name.isNotEmpty
                    ? c.name[0].toUpperCase()
                    : '?'),
              ),
              title: Text(c.name),
              subtitle: Text(
                  '${c.phone} · Owed: ${CurrencyFormatter.format(c.outstandingBalance)}'),
              trailing: TextButton.icon(
                onPressed: () => _restore(context, c),
                icon: const Icon(Icons.restore, size: 16),
                label: const Text('Restore'),
                style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary),
              ),
            ),
          );
        },
      ),
    );
  }
}