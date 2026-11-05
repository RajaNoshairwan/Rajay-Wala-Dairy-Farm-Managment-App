import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../viewmodels/billing_viewmodel.dart';

class PaymentHistoryScreen extends StatelessWidget {
  const PaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BillingViewModel>();
    return Scaffold(
      appBar: AppBar(title: const Text('Payment History')),
      body: vm.payments.isEmpty
          ? const EmptyState(
          message: 'No payments recorded',
          icon: Icons.payments_outlined)
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: vm.payments.length,
        itemBuilder: (context, i) {
          final p = vm.payments[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.check_circle,
                  color: AppColors.success),
              title: Text(CurrencyFormatter.format(p.amount)),
              subtitle: Text(
                  '${AppDateUtils.formatDate(p.paymentDate)} · ${p.method.toUpperCase()}'),
              trailing: p.note.isEmpty ? null : Text(p.note),
            ),
          );
        },
      ),
    );
  }
}