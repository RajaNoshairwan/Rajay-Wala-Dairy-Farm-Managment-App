import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../models/delivery_record_model.dart';
import '../../../models/subscription_model.dart';
import '../../../services/billing_service.dart';
import '../../../services/delivery_service.dart';

class AdminSubscriptionDetailScreen extends StatefulWidget {
  final SubscriptionModel subscription;
  final String customerName;
  final String productName;

  const AdminSubscriptionDetailScreen({
    super.key,
    required this.subscription,
    required this.customerName,
    required this.productName,
  });

  @override
  State<AdminSubscriptionDetailScreen> createState() => _State();
}

class _State extends State<AdminSubscriptionDetailScreen> {
  final _deliveryService = DeliveryService();
  final _billingService = BillingService();
  final _monthFmt = DateFormat('MMMM yyyy');
  final _dayFmt = DateFormat('EEE, dd MMM');

  DateTime _month = DateTime.now();
  Map<String, DeliveryRecordModel> _recordsByDate = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _month = DateTime(
      widget.subscription.startDate.year,
      widget.subscription.startDate.month,
      1,
    );
    _load();
  }

  String _key(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _deliveryService
          .getRecordsForCustomer(widget.subscription.customerId);
      _recordsByDate = {
        for (final r in all.where((r) =>
        r.subscriptionId == widget.subscription.subscriptionId))
          _key(r.date): r
      };
    } catch (e) {
      debugPrint('Load records error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  bool _isInSkipDates(DateTime day) => widget.subscription.skipDates.any(
        (d) => d.year == day.year && d.month == day.month && d.day == day.day,
  );

  bool _isPaused(DateTime day) {
    final s = widget.subscription;
    if (!s.isPaused || s.pausedFrom == null || s.pausedTo == null) return false;
    final from = DateTime(s.pausedFrom!.year, s.pausedFrom!.month, s.pausedFrom!.day);
    final to = DateTime(s.pausedTo!.year, s.pausedTo!.month, s.pausedTo!.day);
    final d = DateTime(day.year, day.month, day.day);
    return !d.isBefore(from) && !d.isAfter(to);
  }

  bool _isOutOfRange(DateTime day) {
    final s = widget.subscription;
    final start = DateTime(s.startDate.year, s.startDate.month, s.startDate.day);
    final end = DateTime(s.endDate.year, s.endDate.month, s.endDate.day);
    final d = DateTime(day.year, day.month, day.day);
    return d.isBefore(start) || d.isAfter(end);
  }

  double _expectedQty(DateTime day) {
    final key = _key(day);
    return widget.subscription.quantityOverrides[key] ??
        widget.subscription.quantityLitres;
  }

  Future<void> _addOrEdit(DateTime day) async {
    final existing = _recordsByDate[_key(day)];
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RecordDialog(
        initial: existing,
        date: day,
        defaultQty: _expectedQty(day),
        defaultPrice: existing?.priceAtDelivery ?? 150,
      ),
    );
    if (result == null) return;
    try {
      final qty = result['qty'] as double;
      final price = result['price'] as double;
      final status = result['status'] as String;
      final recordId = existing?.recordId ??
          'DR-${_key(day)}-${widget.subscription.subscriptionId}';
      await _deliveryService.recordDelivery(
        DeliveryRecordModel(
          recordId: recordId,
          customerId: widget.subscription.customerId,
          subscriptionId: widget.subscription.subscriptionId,
          date: DateTime(day.year, day.month, day.day),
          quantityDelivered: qty,
          priceAtDelivery: price,
          amount: qty * price,
          status: status,
          recordedAt: DateTime.now(),
        ),
      );
      await _billingService
          .recomputeOutstanding(widget.subscription.customerId);
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved · Outstanding updated'),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _delete(DeliveryRecordModel record) async {
    try {
      await _deliveryService.deleteRecord(record.recordId);
      await _billingService
          .recomputeOutstanding(widget.subscription.customerId);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.subscription;
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final days = List.generate(
      daysInMonth,
          (i) => DateTime(_month.year, _month.month, i + 1),
    );

    // Monthly summary
    final monthRecords = _recordsByDate.values
        .where((r) => r.date.year == _month.year && r.date.month == _month.month)
        .toList();
    final monthQty =
    monthRecords.fold<double>(0, (a, r) => a + r.quantityDelivered);
    final monthAmount = monthRecords.fold<double>(0, (a, r) => a + r.amount);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.customerName),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Subscription info',
            onPressed: () => _showInfo(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Subscription summary header
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_drink,
                        color: Colors.white, size: 28),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.productName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    Chip(
                      label: Text(s.status,
                          style: const TextStyle(
                              fontSize: 10, color: Colors.white)),
                      backgroundColor: Colors.white24,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${s.quantityLitres}L per day · ${s.planType} plan',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 13),
                ),
                Text(
                  '${DateFormat('dd MMM yyyy').format(s.startDate)} → ${DateFormat('dd MMM yyyy').format(s.endDate)}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _headerStat(
                          'Delivered', '${monthRecords.length} days'),
                    ),
                    Expanded(
                      child: _headerStat(
                          'Total Qty', '${monthQty.toStringAsFixed(1)}L'),
                    ),
                    Expanded(
                      child: _headerStat(
                          'Amount', CurrencyFormatter.format(monthAmount)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() => _month =
                        DateTime(_month.year, _month.month - 1));
                    _load();
                  },
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
                  onPressed: () {
                    setState(() => _month =
                        DateTime(_month.year, _month.month + 1));
                    _load();
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),

          // Day list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              itemCount: days.length,
              itemBuilder: (context, i) {
                final day = days[i];
                final key = _key(day);
                final record = _recordsByDate[key];
                final skipped = _isInSkipDates(day);
                final paused = _isPaused(day);
                final outOfRange = _isOutOfRange(day);

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  elevation: record != null ? 1 : 0,
                  color: outOfRange
                      ? Colors.grey.shade100
                      : Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        // Date circle
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: record != null
                                ? AppColors.primary.withValues(
                                alpha: 0.12)
                                : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: record != null
                                    ? AppColors.primary
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                _dayFmt.format(day),
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 2),
                              if (outOfRange)
                                Text('Outside subscription range',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600))
                              else if (skipped)
                                Text('Skipped day',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color:
                                        AppColors.warning))
                              else if (paused)
                                  Text('Paused',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color:
                                          AppColors.warning))
                                else if (record != null)
                                    Text(
                                      '${record.quantityDelivered}L · ${CurrencyFormatter.format(record.amount)} · ${record.status}',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    )
                                  else
                                    Text(
                                      'Not delivered yet · Expected ${_expectedQty(day)}L',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.shade600),
                                    ),
                            ],
                          ),
                        ),
                        if (!outOfRange) ...[
                          if (record != null) ...[
                            IconButton(
                              icon: const Icon(Icons.edit,
                                  size: 18, color: AppColors.primary),
                              onPressed: () => _addOrEdit(day),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete,
                                  size: 18, color: Colors.red),
                              onPressed: () => _delete(record),
                            ),
                          ] else
                            IconButton(
                              icon: const Icon(Icons.add_circle,
                                  color: AppColors.primary),
                              onPressed: () => _addOrEdit(day),
                            ),
                        ],
                      ],
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

  Widget _headerStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
            const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _showInfo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Subscription'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Customer: ${widget.customerName}'),
            Text('Product: ${widget.productName}'),
            Text('Plan: ${widget.subscription.planType}'),
            Text('Daily: ${widget.subscription.quantityLitres}L'),
            Text('Status: ${widget.subscription.status}'),
            const SizedBox(height: 8),
            const Text(
              'Tap + on any day to record a delivery. Skipped and paused '
                  'days are labelled automatically. Adding/editing records '
                  'updates the customer\'s outstanding balance in real time.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close')),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Day record edit/add dialog
// ─────────────────────────────────────────────────────────────
class _RecordDialog extends StatefulWidget {
  final DeliveryRecordModel? initial;
  final DateTime date;
  final double defaultQty;
  final double defaultPrice;

  const _RecordDialog({
    this.initial,
    required this.date,
    required this.defaultQty,
    required this.defaultPrice,
  });

  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late String _status;

  @override
  void initState() {
    super.initState();
    _qty = TextEditingController(
        text: (widget.initial?.quantityDelivered ?? widget.defaultQty)
            .toString());
    _price = TextEditingController(
        text:
        (widget.initial?.priceAtDelivery ?? widget.defaultPrice).toString());
    _status = widget.initial?.status ?? 'delivered';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null
          ? 'Add Delivery · ${DateFormat('dd MMM').format(widget.date)}'
          : 'Edit Delivery · ${DateFormat('dd MMM').format(widget.date)}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _qty,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity (litres)'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration:
              const InputDecoration(labelText: 'Price per litre (Rs)'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _status,
              items: const [
                DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
                DropdownMenuItem(value: 'skipped', child: Text('Skipped')),
                DropdownMenuItem(value: 'missed', child: Text('Missed')),
              ],
              onChanged: (v) => setState(() => _status = v ?? 'delivered'),
              decoration: const InputDecoration(labelText: 'Status'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'qty': double.tryParse(_qty.text) ?? 0,
            'price': double.tryParse(_price.text) ?? 0,
            'status': _status,
          }),
          child: const Text('Save'),
        ),
      ],
    );
  }
}