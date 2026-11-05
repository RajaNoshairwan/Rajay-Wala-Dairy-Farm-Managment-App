import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/invoice_model.dart';
import '../../../viewmodels/billing_viewmodel.dart';

class BillDetailScreen extends StatelessWidget {
  final InvoiceModel invoice;
  const BillDetailScreen({super.key, required this.invoice});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bill Details')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: invoice.status == 'paid'
                    ? AppColors.success
                    : AppColors.unpaid,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${_monthName(invoice.month)} ${invoice.year}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(invoice.status.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(CurrencyFormatter.format(invoice.closingBalance),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  Text(
                      'Due: ${AppDateUtils.formatDate(invoice.dueDate)}',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _row('Milk delivered',
                        CurrencyFormatter.format(invoice.totalMilkAmount)),
                    _row('Previous balance',
                        CurrencyFormatter.format(invoice.openingBalance)),
                    _row('Payment received',
                        '- ${CurrencyFormatter.format(invoice.paymentsReceived)}'),
                    const Divider(),
                    _row(
                        'Remaining balance',
                        CurrencyFormatter.format(
                            invoice.closingBalance),
                        bold: true),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            CustomButton(
              label: 'Download Invoice PDF',
              icon: Icons.download,
              onPressed: () => context
                  .read<BillingViewModel>()
                  .downloadInvoice(invoice),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
      fontSize: bold ? 16 : 14,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
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