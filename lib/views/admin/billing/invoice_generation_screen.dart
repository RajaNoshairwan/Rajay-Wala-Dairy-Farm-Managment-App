import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/invoice_model.dart';

class InvoiceGenerationScreen extends StatefulWidget {
  const InvoiceGenerationScreen({super.key});
  @override
  State<InvoiceGenerationScreen> createState() => _State();
}

class _State extends State<InvoiceGenerationScreen> {
  final _genFmt = DateFormat('dd MMM yyyy · hh:mm a');
  final _dueFmt = DateFormat('dd MMM yyyy');
  Map<String, String> _names = {};

  @override
  void initState() {
    super.initState();
    _loadNames();
  }

  Future<void> _loadNames() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();
      if (!mounted) return;
      setState(() {
        _names = {
          for (var d in snap.docs)
            d.id: ((d.data()['name'] ?? '') as String).isEmpty
                ? 'Unknown'
                : (d.data()['name'] as String)
        };
      });
    } catch (e) {
      debugPrint('Load names error: $e');
    }
  }

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('All Invoices')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('invoices')
            .orderBy('generatedAt', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Error: ${snap.error}', textAlign: TextAlign.center),
              ),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final invoices = snap.data!.docs
              .map((d) => InvoiceModel.fromMap(d.id, d.data()))
              .toList();
          if (invoices.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No invoices generated yet.\nGo back and tap "Generate All Invoices".',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invoices.length,
            itemBuilder: (context, i) {
              final inv = invoices[i];
              final name = _names[inv.customerId] ?? inv.customerId;
              final paidColor = inv.status == 'paid'
                  ? AppColors.paid
                  : inv.status == 'partiallyPaid'
                  ? AppColors.partiallyPaid
                  : AppColors.unpaid;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: paidColor.withValues(alpha: 0.15),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: paidColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                Text(
                                  '${_monthName(inv.month)} ${inv.year}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: paidColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              inv.status.toUpperCase(),
                              style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: paidColor),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _row('Milk amount',
                          CurrencyFormatter.format(inv.totalMilkAmount)),
                      _row('Previous balance',
                          CurrencyFormatter.format(inv.openingBalance)),
                      _row('Payments received',
                          '- ${CurrencyFormatter.format(inv.paymentsReceived)}'),
                      const SizedBox(height: 6),
                      _row(
                        'Balance Due',
                        CurrencyFormatter.format(inv.closingBalance),
                        bold: true,
                        color: paidColor,
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          const Icon(Icons.event_available,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Text('Due: ${_dueFmt.format(inv.dueDate)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Generated: ${_genFmt.format(inv.generatedAt)}',
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _row(String label, String value,
      {bool bold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: bold ? 14 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  color: AppColors.textSecondary)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 15 : 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w500,
                  color: color ?? AppColors.textPrimary)),
        ],
      ),
    );
  }
}