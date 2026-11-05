import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/ledger_entry_model.dart';

class CustomerLedgerScreen extends StatelessWidget {
  final String customerId;
  const CustomerLedgerScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Customer Ledger')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('ledger_entries')
            .where('customerId', isEqualTo: customerId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final entries = snap.data!.docs.map((d) => LedgerEntryModel.fromMap(d.id, d.data())).toList()
            ..sort((a, b) => b.date.compareTo(a.date));
          if (entries.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.menu_book, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  const Text('No ledger entries yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Ledger entries are created automatically when you generate invoices or record payments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary)),
                ]),
              ),
            );
          }
          return Column(children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.primary,
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Running Balance', style: TextStyle(color: Colors.white70)),
                Text(CurrencyFormatter.format(entries.first.balance),
                    style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ]),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: entries.length,
                itemBuilder: (context, i) {
                  final e = entries[i];
                  return ListTile(
                    dense: true,
                    leading: Icon(e.debit > 0 ? Icons.arrow_upward : Icons.arrow_downward,
                        color: e.debit > 0 ? AppColors.unpaid : AppColors.paid),
                    title: Text(e.description),
                    subtitle: Text(AppDateUtils.formatDate(e.date)),
                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(e.debit > 0 ? 'Dr ${CurrencyFormatter.format(e.debit)}' : 'Cr ${CurrencyFormatter.format(e.credit)}',
                          style: TextStyle(color: e.debit > 0 ? AppColors.unpaid : AppColors.paid, fontWeight: FontWeight.bold)),
                      Text('Bal: ${CurrencyFormatter.format(e.balance)}', style: const TextStyle(fontSize: 11)),
                    ]),
                  );
                },
              ),
            ),
          ]);
        },
      ),
    );
  }
}