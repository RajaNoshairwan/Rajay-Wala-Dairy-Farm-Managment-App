import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../viewmodels/admin_billing_viewmodel.dart';
import 'invoice_generation_screen.dart';

class AdminBillingScreen extends StatelessWidget {
  const AdminBillingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminBillingViewModel>();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Billing Management',
            style:
            TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text(
          'Generate monthly invoices automatically from actual delivery records. '
              'Balances are carried forward from the previous month.',
          style: TextStyle(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Current Month',
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(AppDateUtils.formatMonth(DateTime.now()),
                    style: const TextStyle(
                        color: AppColors.textSecondary)),
                const SizedBox(height: 16),
                CustomButton(
                  label: 'Generate All Invoices',
                  icon: Icons.autorenew,
                  loading: vm.loading,
                  onPressed: () async {
                    final now = DateTime.now();
                    await vm.generateAllInvoices(
                        now.month, now.year);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(vm.message ??
                                'Invoices generated')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.receipt_long,
                color: AppColors.primary),
            title: const Text('View All Invoices'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) =>
                  const InvoiceGenerationScreen()),
            ),
          ),
        ),
      ],
    );
  }
}