import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/billing_viewmodel.dart';
import 'bill_detail_screen.dart';

class BillListScreen extends StatefulWidget {
  const BillListScreen({super.key});

  @override
  State<BillListScreen> createState() => _BillListScreenState();
}

class _BillListScreenState extends State<BillListScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid != null) {
      context.read<BillingViewModel>().loadCustomerBilling(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<BillingViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Bills')),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.invoices.isEmpty
          ? const EmptyState(
          message: 'No invoices yet',
          icon: Icons.receipt_long_outlined)
          : Column(
        children: [
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Outstanding',
                    style: TextStyle(
                        color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 4),
                Text(
                    CurrencyFormatter.format(
                        vm.totalOutstanding),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.symmetric(horizontal: 12),
              itemCount: vm.invoices.length,
              itemBuilder: (context, i) {
                final inv = vm.invoices[i];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    title: Text(
                        '${_monthName(inv.month)} ${inv.year}'),
                    subtitle: Text(
                        'Milk: ${CurrencyFormatter.format(inv.totalMilkAmount)} · Paid: ${CurrencyFormatter.format(inv.paymentsReceived)}'),
                    trailing: Column(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      crossAxisAlignment:
                      CrossAxisAlignment.end,
                      children: [
                        Text(
                            CurrencyFormatter.format(
                                inv.closingBalance),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: inv.status == 'paid'
                                    ? AppColors.paid
                                    : AppColors.unpaid)),
                        Text(inv.status,
                            style: TextStyle(
                                fontSize: 11,
                                color: inv.status == 'paid'
                                    ? AppColors.paid
                                    : AppColors.unpaid)),
                      ],
                    ),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BillDetailScreen(invoice: inv),
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

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m - 1];
  }
}