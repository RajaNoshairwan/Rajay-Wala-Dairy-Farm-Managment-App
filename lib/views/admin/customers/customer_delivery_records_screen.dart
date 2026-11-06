import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/delivery_record_model.dart';
import '../../../services/billing_service.dart';

class CustomerDeliveryRecordsScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  const CustomerDeliveryRecordsScreen({
    super.key,
    required this.customerId,
    required this.customerName,
  });
  @override
  State<CustomerDeliveryRecordsScreen> createState() => _State();
}

class _State extends State<CustomerDeliveryRecordsScreen> {
  final _monthFmt = DateFormat('MMMM yyyy');
  final _billing = BillingService();
  DateTime _month = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customerName)),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('delivery_records')
            .where('customerId', isEqualTo: widget.customerId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error: ${snap.error}'),
                ));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final start = DateTime(_month.year, _month.month, 1);
          final end = DateTime(_month.year, _month.month + 1, 1);
          final recordsByDay = <int, DeliveryRecordModel>{};
          for (final d in snap.data!.docs) {
            final r = DeliveryRecordModel.fromMap(d.id, d.data());
            if (!r.date.isBefore(start) && r.date.isBefore(end)) {
              recordsByDay[r.date.day] = r;
            }
          }

          final totalKg = recordsByDay.values
              .fold<double>(0.0, (s, r) => s + r.quantityDelivered);
          final totalAmount =
          recordsByDay.values.fold<double>(0.0, (s, r) => s + r.amount);
          final deliveredDays = recordsByDay.values
              .where((r) => r.quantityDelivered > 0)
              .length;

          return Column(
            children: [
              // Month navigation
              Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => setState(() => _month =
                          DateTime(_month.year, _month.month - 1)),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          _monthFmt.format(_month),
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => setState(() => _month =
                          DateTime(_month.year, _month.month + 1)),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: _buildCalendar(recordsByDay),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildTotals(
                        deliveredDays, totalKg, totalAmount),
                    const SizedBox(height: 8),
                    Text(
                      'Tap any day to add or edit. Data syncs everywhere in real time.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCalendar(Map<int, DeliveryRecordModel> recordsByDay) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday;
    final cells = <Widget>[];

    // Weekday headers
    for (final w in <String>['M', 'T', 'W', 'T', 'F', 'S', 'S']) {
      cells.add(Center(
        child: Text(w,
            style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.textSecondary)),
      ));
    }

    // Leading blanks
    for (int i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox());
    }

    // Day cells
    for (int d = 1; d <= daysInMonth; d++) {
      final rec = recordsByDay[d];
      final kg = rec?.quantityDelivered ?? 0.0;
      final status = rec?.status ?? '';

      Color bg;
      Color fg;
      if (status == 'delivered') {
        bg = AppColors.primary.withValues(alpha: 0.15);
        fg = AppColors.primary;
      } else if (status == 'skipped' || status == 'missed') {
        bg = AppColors.warning.withValues(alpha: 0.15);
        fg = AppColors.warning;
      } else {
        bg = Colors.grey.shade100;
        fg = Colors.grey.shade600;
      }

      cells.add(
        GestureDetector(
          onTap: () => _editDay(d, rec),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(8)),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '$d',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: fg),
                ),
                if (kg > 0)
                  Text(
                    '${kg.toStringAsFixed(0)}k',
                    style: TextStyle(
                        fontSize: 10,
                        color: fg,
                        fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 0.9,
      children: cells,
    );
  }

  Widget _buildTotals(int days, double kg, double amount) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _stat('Days', '$days'),
            _stat('Total kg', '${kg.toStringAsFixed(1)} kg'),
            _stat('Amount', CurrencyFormatter.format(amount)),
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
      const SizedBox(height: 4),
      Text(value,
          style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary)),
    ],
  );

  Future<void> _editDay(int day, DeliveryRecordModel? existing) async {
    final defaultRate = existing?.priceAtDelivery ?? 150.0;
    final qtyCtrl = TextEditingController(
        text: existing?.quantityDelivered.toString() ?? '');
    final rateCtrl =
    TextEditingController(text: defaultRate.toStringAsFixed(0));
    String status = existing?.status ?? 'delivered';

    final action = await showDialog<String>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: Text(DateFormat('dd MMM yyyy')
              .format(DateTime(_month.year, _month.month, day))),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Quantity (kg)',
                      helperText: 'Set 0 to clear'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: rateCtrl,
                  keyboardType: TextInputType.number,
                  decoration:
                  const InputDecoration(labelText: 'Rate per kg (Rs)'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: status,
                  items: const [
                    DropdownMenuItem(
                        value: 'delivered', child: Text('Delivered')),
                    DropdownMenuItem(
                        value: 'skipped', child: Text('Skipped')),
                    DropdownMenuItem(
                        value: 'missed', child: Text('Missed')),
                  ],
                  onChanged: (v) =>
                      setS(() => status = v ?? 'delivered'),
                  decoration:
                  const InputDecoration(labelText: 'Status'),
                ),
              ],
            ),
          ),
          actions: [
            if (existing != null)
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'delete'),
                child: const Text('Delete',
                    style: TextStyle(color: Colors.red)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: const Text('Cancel')),
            ElevatedButton(
                onPressed: () => Navigator.pop(ctx, 'save'),
                child: const Text('Save')),
          ],
        ),
      ),
    );

    if (action == 'save') {
      final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
      final rate = double.tryParse(rateCtrl.text) ?? 0.0;
      final recordId = existing?.recordId ??
          'MANUAL-${_month.year}-${_month.month}-${day}-${widget.customerId}';

      try {
        if (qty <= 0) {
          if (existing != null) {
            await FirebaseFirestore.instance
                .collection('delivery_records')
                .doc(existing.recordId)
                .delete();
          }
        } else {
          await FirebaseFirestore.instance
              .collection('delivery_records')
              .doc(recordId)
              .set(DeliveryRecordModel(
            recordId: recordId,
            customerId: widget.customerId,
            subscriptionId: existing?.subscriptionId ?? '',
            date: DateTime(_month.year, _month.month, day),
            quantityDelivered: qty,
            priceAtDelivery: rate,
            amount: qty * rate,
            status: status,
            recordedAt: DateTime.now(),
          ).toMap());
        }
        await _billing.recomputeOutstanding(widget.customerId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else if (action == 'delete' && existing != null) {
      try {
        await FirebaseFirestore.instance
            .collection('delivery_records')
            .doc(existing.recordId)
            .delete();
        await _billing.recomputeOutstanding(widget.customerId);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}