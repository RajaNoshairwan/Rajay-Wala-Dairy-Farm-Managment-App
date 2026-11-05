import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/user_model.dart';
import '../../../viewmodels/admin_customer_viewmodel.dart';
import '../billing/customer_ledger_screen.dart';
import 'customer_delivery_records_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final UserModel customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _State();
}

class _State extends State<CustomerDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminCustomerViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(widget.customer.name)),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.customer.uid)
            .snapshots(),
        builder: (context, snap) {
          // Use live doc if available, otherwise fall back to passed-in data.
          final customer = (snap.hasData && snap.data!.exists)
              ? UserModel.fromMap(
              widget.customer.uid, snap.data!.data()!)
              : widget.customer;

          final owes = customer.outstandingBalance;
          final isDebtor = owes > 0;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ─── Profile card ────────────────────────────────
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Name', customer.name),
                      _row('Phone', customer.phone),
                      _row('Email',
                          customer.email.isEmpty ? '—' : customer.email),
                      _row('Address', customer.address.fullAddress),
                      _row('Registered',
                          AppDateUtils.formatDate(customer.createdAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ─── Outstanding balance hero card ───────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDebtor
                        ? const [Color(0xFFE53935), Color(0xFFC62828)]
                        : const [Color(0xFF43A047), Color(0xFF2E7D32)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: (isDebtor ? Colors.red : Colors.green)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isDebtor
                              ? Icons.warning_amber_rounded
                              : Icons.verified_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Outstanding Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      CurrencyFormatter.format(owes),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.bold,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      isDebtor
                          ? 'Total unpaid amount across all deliveries and invoices.'
                          : 'All clear — no pending balance.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                              color: Colors.white.withValues(alpha: 0.5)),
                          padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CustomerLedgerScreen(
                                customerId: customer.uid),
                          ),
                        ),
                        icon: const Icon(Icons.menu_book, size: 16),
                        label: const Text('View Ledger',
                            style: TextStyle(fontSize: 12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // ─── Actions ─────────────────────────────────────
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delivery_dining,
                      color: AppColors.primary),
                  title: const Text('Delivery Records'),
                  subtitle:
                  const Text('Add or edit daily delivery quantity & price'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CustomerDeliveryRecordsScreen(
                          customerId: customer.uid,
                          customerName: customer.name,
                        ),
                      ),
                    );
                    // StreamBuilder above will auto-refresh when
                    // outstandingBalance is updated in Firestore —
                    // no manual reload needed.
                  },
                ),
              ),
              Card(
                child: ListTile(
                  leading:
                  const Icon(Icons.menu_book, color: AppColors.primary),
                  title: const Text('Ledger'),
                  subtitle: const Text(
                      'Full transaction history (debits + credits)'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          CustomerLedgerScreen(customerId: customer.uid),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Block Customer'),
                subtitle: const Text(
                    'Blocked customers cannot place new orders'),
                value: customer.isBlocked,
                onChanged: (_) => vm.toggleBlock(customer),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}