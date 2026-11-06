import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/user_model.dart';
import '../../../models/delivery_record_model.dart';
import '../../../models/payment_model.dart';
import '../../../services/map_service.dart';
import '../billing/customer_ledger_screen.dart';
import 'customer_delivery_records_screen.dart';
import 'customer_edit_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final UserModel customer;
  const CustomerDetailScreen({super.key, required this.customer});
  @override
  State<CustomerDetailScreen> createState() => _State();
}

class _State extends State<CustomerDetailScreen> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.customer.uid)
          .snapshots(),
      builder: (context, userSnap) {
        final customer = (userSnap.hasData && userSnap.data!.exists)
            ? UserModel.fromMap(widget.customer.uid, userSnap.data!.data()!)
            : widget.customer;

        final hasLocation = customer.address.lat != 0 || customer.address.lng != 0;

        return Scaffold(
          appBar: AppBar(
            title: Text(customer.name),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit),
                tooltip: 'Edit Profile',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          CustomerEditScreen(customer: customer)),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _row('Name', customer.name),
                      _row('Phone', customer.phone),
                      _row(
                          'Emergency',
                          customer.emergencyContact.isEmpty
                              ? '—'
                              : customer.emergencyContact),
                      _row(
                          'Rate per kg',
                          customer.ratePerKg > 0
                              ? 'Rs. ${customer.ratePerKg.toStringAsFixed(0)}'
                              : '—'),
                      _row('Registered',
                          AppDateUtils.formatDate(customer.createdAt)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ─── Delivery Location card (view + directions) ──
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: AppColors.primary, size: 18),
                          const SizedBox(width: 6),
                          const Text('Delivery Location',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        customer.address.fullAddress.isEmpty
                            ? 'No address saved'
                            : customer.address.fullAddress,
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (hasLocation) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${customer.address.lat.toStringAsFixed(5)}, '
                              '${customer.address.lng.toStringAsFixed(5)}',
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.map, size: 16),
                                label: const Text('View on Map',
                                    style: TextStyle(fontSize: 12)),
                                onPressed: () => MapService.viewLocation(
                                    customer.address.lat,
                                    customer.address.lng),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.directions,
                                    size: 16),
                                label: const Text('Directions',
                                    style: TextStyle(fontSize: 12)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                ),
                                onPressed: () => MapService.getDirections(
                                    customer.address.lat,
                                    customer.address.lng),
                              ),
                            ),
                          ],
                        ),
                      ] else
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            'No coordinates saved. Edit customer to pick a location on the map.',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              _CalendarCard(
                customerId: customer.uid,
                customerName: customer.name,
              ),
              const SizedBox(height: 12),
              _TransactionsCard(customerId: customer.uid),
              const SizedBox(height: 12),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.delivery_dining,
                      color: AppColors.primary),
                  title: const Text('Full Delivery Records'),
                  subtitle:
                  const Text('Open calendar to edit every day'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CustomerDeliveryRecordsScreen(
                        customerId: customer.uid,
                        customerName: customer.name,
                      ),
                    ),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.menu_book,
                      color: AppColors.primary),
                  title: const Text('Ledger'),
                  subtitle:
                  const Text('Debits + credits with running balance'),
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
            ],
          ),
        );
      },
    );
  }

  Widget _row(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(color: AppColors.textSecondary)),
        ),
        Expanded(child: Text(value)),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────
// Calendar preview card (unchanged)
// ─────────────────────────────────────────────────────────────
class _CalendarCard extends StatefulWidget {
  final String customerId;
  final String customerName;
  const _CalendarCard({
    required this.customerId,
    required this.customerName,
  });
  @override
  State<_CalendarCard> createState() => _CalendarCardState();
}

class _CalendarCardState extends State<_CalendarCard> {
  final _monthFmt = DateFormat('MMMM yyyy');
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_month,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 6),
                const Text('Monthly Calendar',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  iconSize: 18,
                  onPressed: () => setState(() => _month =
                      DateTime(_month.year, _month.month - 1)),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(_monthFmt.format(_month),
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
                IconButton(
                  iconSize: 18,
                  onPressed: () => setState(() => _month =
                      DateTime(_month.year, _month.month + 1)),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 4),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('delivery_records')
                  .where('customerId', isEqualTo: widget.customerId)
                  .snapshots(),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Error: ${snap.error}',
                        style: const TextStyle(fontSize: 11)),
                  );
                }
                if (!snap.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(20),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final start = DateTime(_month.year, _month.month, 1);
                final end = DateTime(_month.year, _month.month + 1, 0);
                final byDay = <int, DeliveryRecordModel>{};
                for (final d in snap.data!.docs) {
                  final r = DeliveryRecordModel.fromMap(d.id, d.data());
                  if (r.date.year == _month.year &&
                      r.date.month == _month.month) {
                    byDay[r.date.day] = r;
                  }
                }
                final daysInMonth = end.day;
                final firstWeekday = start.weekday;
                final cells = <Widget>[];

                for (final w in <String>[
                  'M',
                  'T',
                  'W',
                  'T',
                  'F',
                  'S',
                  'S'
                ]) {
                  cells.add(Center(
                    child: Text(w,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textSecondary)),
                  ));
                }
                for (int i = 1; i < firstWeekday; i++) {
                  cells.add(const SizedBox());
                }
                for (int d = 1; d <= daysInMonth; d++) {
                  final rec = byDay[d];
                  final kg = rec?.quantityDelivered ?? 0.0;
                  final status = rec?.status ?? '';
                  Color bg;
                  Color fg;
                  if (status == 'delivered') {
                    bg = AppColors.primary.withValues(alpha: 0.15);
                    fg = AppColors.primary;
                  } else if (status == 'skipped' ||
                      status == 'missed') {
                    bg = AppColors.warning.withValues(alpha: 0.15);
                    fg = AppColors.warning;
                  } else {
                    bg = Colors.grey.shade100;
                    fg = Colors.grey.shade500;
                  }
                  cells.add(Container(
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(6)),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$d',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: fg)),
                        if (kg > 0)
                          Text('${kg.toStringAsFixed(1)}k',
                              style: TextStyle(
                                  fontSize: 9, color: fg)),
                      ],
                    ),
                  ));
                }

                final totalKg = byDay.values
                    .fold<double>(0.0, (s, r) => s + r.quantityDelivered);
                final totalAmount = byDay.values
                    .fold<double>(0.0, (s, r) => s + r.amount);

                return Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 7,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 0.9,
                      children: cells,
                    ),
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.spaceAround,
                      children: [
                        _stat('Days', '${byDay.length}'),
                        _stat('Total kg',
                            '${totalKg.toStringAsFixed(1)} kg'),
                        _stat('Amount',
                            CurrencyFormatter.format(totalAmount)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit_calendar,
                            size: 16),
                        label: const Text('Edit Days'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDeliveryRecordsScreen(
                                  customerId: widget.customerId,
                                  customerName: widget.customerName,
                                ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _stat(String label, String value) => Column(
    children: [
      Text(label,
          style: const TextStyle(
              fontSize: 11, color: AppColors.textSecondary)),
      const SizedBox(height: 2),
      Text(value,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary)),
    ],
  );
}

// ─────────────────────────────────────────────────────────────
// Transactions card — unchanged from previous version
// ─────────────────────────────────────────────────────────────
class _TransactionsCard extends StatelessWidget {
  final String customerId;
  const _TransactionsCard({required this.customerId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('payments')
          .where('customerId', isEqualTo: customerId)
          .snapshots(),
      builder: (context, paySnap) {
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('delivery_records')
              .where('customerId', isEqualTo: customerId)
              .snapshots(),
          builder: (context, delSnap) {
            final ready = paySnap.hasData && delSnap.hasData;
            final deliveries = ready
                ? delSnap.data!.docs
                .map((d) =>
                DeliveryRecordModel.fromMap(d.id, d.data()))
                .toList()
                : <DeliveryRecordModel>[];
            final payments = ready
                ? paySnap.data!.docs
                .map((d) => PaymentModel.fromMap(d.id, d.data()))
                .toList()
                : <PaymentModel>[];

            final totalOwed = deliveries.fold<double>(
                0.0, (s, d) => s + d.amount);
            final totalReceived = payments
                .where((p) => p.status != 'pending')
                .fold<double>(0.0, (s, p) => s + p.amount);
            final totalPending = payments
                .where((p) => p.status == 'pending')
                .fold<double>(0.0, (s, p) => s + p.amount);
            final remaining = totalOwed - totalReceived;

            final txs = <_Tx>[];
            for (final d in deliveries) {
              if (d.amount <= 0) continue;
              txs.add(_Tx(
                  date: d.date,
                  description:
                  'Delivery ${d.quantityDelivered.toStringAsFixed(1)}kg @ ${d.priceAtDelivery.toStringAsFixed(0)}',
                  debit: d.amount));
            }
            for (final p in payments) {
              txs.add(_Tx(
                date: p.paymentDate,
                description:
                '${p.status == 'pending' ? 'Pending' : 'Received'} · ${p.method}',
                credit: p.status == 'pending' ? 0.0 : p.amount,
                payment: p,
              ));
            }
            txs.sort((a, b) => a.date.compareTo(b.date));
            double bal = 0.0;
            for (final t in txs) {
              bal += t.debit - t.credit;
              t.balance = bal;
            }

            return Card(
              child: Theme(
                data: Theme.of(context)
                    .copyWith(dividerColor: Colors.transparent),
                child: ExpansionTile(
                  leading: const Icon(Icons.receipt_long,
                      color: AppColors.primary),
                  title: const Text('Transactions',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _pill('Received',
                          CurrencyFormatter.format(totalReceived),
                          AppColors.success),
                      _pill('Pending',
                          CurrencyFormatter.format(totalPending),
                          AppColors.warning),
                      _pill(
                          'Remaining',
                          CurrencyFormatter.format(
                              remaining < 0 ? 0 : remaining),
                          remaining > 0
                              ? AppColors.unpaid
                              : AppColors.paid),
                    ],
                  ),
                  children: [
                    if (!ready)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(),
                      )
                    else if (txs.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Text('No transactions yet'),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        padding: EdgeInsets.zero,
                        itemCount: txs.length,
                        itemBuilder: (context, i) {
                          final t = txs[i];
                          final isPayment = t.payment != null;
                          final isPending = t.payment?.status ==
                              'pending';
                          return ListTile(
                            dense: true,
                            onTap: isPayment
                                ? () => _editPayment(
                                context, t.payment!)
                                : null,
                            leading: Icon(
                              isPayment
                                  ? (isPending
                                  ? Icons.schedule
                                  : Icons.check_circle)
                                  : Icons.arrow_upward,
                              color: isPayment
                                  ? (isPending
                                  ? AppColors.warning
                                  : AppColors.success)
                                  : AppColors.unpaid,
                              size: 18,
                            ),
                            title: Text(t.description,
                                style:
                                const TextStyle(fontSize: 13)),
                            subtitle: Text(
                                AppDateUtils.formatDate(t.date),
                                style: const TextStyle(fontSize: 11)),
                            trailing: Column(
                              mainAxisAlignment:
                              MainAxisAlignment.center,
                              crossAxisAlignment:
                              CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isPayment
                                      ? (isPending
                                      ? 'Pend ${CurrencyFormatter.format(t.payment!.amount)}'
                                      : 'Cr ${CurrencyFormatter.format(t.payment!.amount)}')
                                      : 'Dr ${CurrencyFormatter.format(t.debit)}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: isPayment
                                          ? (isPending
                                          ? AppColors.warning
                                          : AppColors.paid)
                                          : AppColors.unpaid),
                                ),
                                Text(
                                    'Bal: ${CurrencyFormatter.format(t.balance)}',
                                    style: const TextStyle(
                                        fontSize: 10)),
                              ],
                            ),
                          );
                        },
                      ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Payment'),
                        onPressed: () => _addPayment(context),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _pill(String label, String value, Color color) => Container(
    padding:
    const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text('$label: $value',
        style: TextStyle(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.w600)),
  );

  Future<void> _recompute() async {
    final db = FirebaseFirestore.instance;
    final records = await db
        .collection('delivery_records')
        .where('customerId', isEqualTo: customerId)
        .get();
    final payments = await db
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .get();
    double owed = 0.0, paid = 0.0;
    for (final r in records.docs) {
      owed += ((r.data()['amount'] ?? 0) as num).toDouble();
    }
    for (final p in payments.docs) {
      final status = (p.data()['status'] as String?) ?? 'received';
      if (status == 'pending') continue;
      paid += ((p.data()['amount'] ?? 0) as num).toDouble();
    }
    await db
        .collection('users')
        .doc(customerId)
        .update({'outstandingBalance': owed - paid});
  }

  Future<void> _addPayment(BuildContext context) async {
    final result = await _showPaymentDialog(context);
    if (result == null) return;

    try {
      await FirebaseFirestore.instance.collection('payments').add({
        'customerId': customerId,
        'invoiceId': null,
        'amount': result['amount'],
        'paymentDate': Timestamp.now(),
        'method': result['method'],
        'status': result['status'],
        'recordedBy': '',
        'note': result['note'],
      });
      await _recompute();
    } catch (e) {
      debugPrint('Add payment error: $e');
    }
  }

  Future<void> _editPayment(
      BuildContext context, PaymentModel payment) async {
    final result = await _showPaymentDialog(
      context,
      initial: payment,
      allowDelete: true,
    );
    if (result == null) return;

    try {
      if (result['delete'] == true) {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(payment.paymentId)
            .delete();
      } else {
        await FirebaseFirestore.instance
            .collection('payments')
            .doc(payment.paymentId)
            .update({
          'amount': result['amount'],
          'method': result['method'],
          'status': result['status'],
          'note': result['note'],
        });
      }
      await _recompute();
    } catch (e) {
      debugPrint('Edit payment error: $e');
    }
  }

  Future<Map<String, dynamic>?> _showPaymentDialog(
      BuildContext context, {
        PaymentModel? initial,
        bool allowDelete = false,
      }) async {
    final amountCtrl = TextEditingController(
        text: initial != null ? initial.amount.toString() : '');
    final noteCtrl = TextEditingController(text: initial?.note ?? '');
    String method = initial?.method ?? 'cash';
    String status = initial?.status ?? 'received';

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(initial == null ? 'Add Payment' : 'Edit Payment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: amountCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                  const InputDecoration(labelText: 'Amount (Rs)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: method,
                  items: const [
                    DropdownMenuItem(
                        value: 'cash', child: Text('Cash')),
                    DropdownMenuItem(
                        value: 'online', child: Text('Online')),
                  ],
                  onChanged: (v) =>
                      setS(() => method = v ?? 'cash'),
                  decoration:
                  const InputDecoration(labelText: 'Mode'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(
                        value: 'received', child: Text('Received')),
                    DropdownMenuItem(
                        value: 'pending', child: Text('Pending')),
                  ],
                  onChanged: (v) =>
                      setS(() => status = v ?? 'received'),
                  decoration:
                  const InputDecoration(labelText: 'Status'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: noteCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Note (optional)'),
                ),
              ],
            ),
          ),
          actions: [
            if (allowDelete)
              TextButton(
                onPressed: () =>
                    Navigator.pop(ctx, {'delete': true}),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                final amount = double.tryParse(amountCtrl.text) ?? 0.0;
                if (amount <= 0) return;
                Navigator.pop(ctx, {
                  'amount': amount,
                  'method': method,
                  'status': status,
                  'note': noteCtrl.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
    return result;
  }
}

class _Tx {
  final DateTime date;
  final String description;
  final double debit;
  final double credit;
  final PaymentModel? payment;
  double balance = 0.0;
  _Tx({
    required this.date,
    required this.description,
    this.debit = 0.0,
    this.credit = 0.0,
    this.payment,
  });
}