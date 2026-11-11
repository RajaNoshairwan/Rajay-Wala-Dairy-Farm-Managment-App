import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/user_model.dart';
import '../../../models/delivery_record_model.dart';

class CustomerBillScreen extends StatefulWidget {
  final UserModel customer;
  const CustomerBillScreen({super.key, required this.customer});
  @override
  State<CustomerBillScreen> createState() => _State();
}

class _State extends State<CustomerBillScreen> {
  final _fmt = DateFormat('dd MMM yyyy');
  DateTime _from = DateTime.now().subtract(const Duration(days: 29));
  DateTime _to = DateTime.now();
  List<DeliveryRecordModel> _records = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // Single-field query — no composite index required
      final snap = await FirebaseFirestore.instance
          .collection('delivery_records')
          .where('customerId', isEqualTo: widget.customer.uid)
          .get();

      final fromN = DateTime(_from.year, _from.month, _from.day);
      final toN = DateTime(_to.year, _to.month, _to.day)
          .add(const Duration(days: 1));

      _records = snap.docs
          .map((d) => DeliveryRecordModel.fromMap(d.id, d.data()))
          .where((r) => !r.date.isBefore(fromN) && r.date.isBefore(toN))
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) {
      debugPrint('Bill load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) {
      setState(() => _from = d);
      if (_from.isAfter(_to)) _to = _from;
      await _load();
    }
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null && mounted) {
      setState(() => _to = d);
      await _load();
    }
  }

  void _quickRange(String preset) {
    final now = DateTime.now();
    setState(() {
      switch (preset) {
        case 'week':
          final monday =
          now.subtract(Duration(days: (now.weekday - 1)));
          _from = DateTime(monday.year, monday.month, monday.day);
          _to = _from.add(const Duration(days: 6));
          break;
        case 'month':
          _from = DateTime(now.year, now.month, 1);
          _to = DateTime(now.year, now.month + 1, 0);
          break;
        case '7':
          _from = now.subtract(const Duration(days: 6));
          _to = now;
          break;
        case '30':
          _from = now.subtract(const Duration(days: 29));
          _to = now;
          break;
      }
    });
    _load();
  }

  double get _totalKg =>
      _records.fold(0.0, (s, r) => s + r.quantityDelivered);
  double get _totalAmount =>
      _records.fold(0.0, (s, r) => s + r.amount);

  String _fmtKg(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final rate = widget.customer.ratePerKg;
    final effectiveRate =
    _totalKg > 0 ? _totalAmount / _totalKg : rate;
    final hasVaryingRate =
        rate > 0 && _totalKg > 0 && (effectiveRate - rate).abs() > 0.01;

    return Scaffold(
      appBar: AppBar(title: Text('${widget.customer.name} · Bill')),
      body: Column(
        children: [
          // ── Date range picker ─────────────────────────────
          Card(
            margin: const EdgeInsets.all(12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today,
                              size: 16),
                          label: Text(_fmt.format(_from),
                              style: const TextStyle(fontSize: 12)),
                          onPressed: _pickFrom,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text('→'),
                      ),
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.calendar_today,
                              size: 16),
                          label: Text(_fmt.format(_to),
                              style: const TextStyle(fontSize: 12)),
                          onPressed: _pickTo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ActionChip(
                          label: const Text('This Week'),
                          onPressed: () => _quickRange('week')),
                      ActionChip(
                          label: const Text('This Month'),
                          onPressed: () => _quickRange('month')),
                      ActionChip(
                          label: const Text('Last 7 days'),
                          onPressed: () => _quickRange('7')),
                      ActionChip(
                          label: const Text('Last 30 days'),
                          onPressed: () => _quickRange('30')),
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (_loading)
            const Expanded(
                child: Center(child: CircularProgressIndicator()))
          else ...[
            // ── Summary card ────────────────────────────────
            Card(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              // color: AppColors.primary.withValues(alpha: 0.06),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.customer.name,
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _row('Rate per kg',
                        rate > 0
                            ? 'Rs. ${rate.toStringAsFixed(0)}'
                            : '—'),
                    _row('Days From', _fmt.format(_from)),
                    _row('Days To', _fmt.format(_to)),
                    _row('Total Days', '${_records.length}'),
                    const Divider(height: 18),
                    _row('Total kgs',
                        '${_fmtKg(_totalKg)} kg'),
                    _row(
                        'Total Amount',
                        CurrencyFormatter.format(_totalAmount),
                        bold: true),
                    if (hasVaryingRate)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          'Rate varied on some deliveries · avg Rs. ${effectiveRate.toStringAsFixed(2)}/kg',
                          style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: Colors.grey.shade700),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Day-by-day',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _records.isEmpty
                  ? Center(
                child: Text(
                  'No deliveries in this range',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
                  : ListView.builder(
                padding:
                const EdgeInsets.fromLTRB(12, 0, 12, 12),
                itemCount: _records.length,
                itemBuilder: (context, i) {
                  final r = _records[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary
                            .withValues(alpha: 0.12),
                        child: Text('${r.date.day}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ),
                      title: Text(
                          AppDateUtils.formatDate(r.date),
                          style: const TextStyle(fontSize: 13)),
                      subtitle: Text(
                        '${_fmtKg(r.quantityDelivered)} kg × Rs. ${r.priceAtDelivery.toStringAsFixed(0)}',
                        style:
                        const TextStyle(fontSize: 11),
                      ),
                      trailing: Text(
                          CurrencyFormatter.format(r.amount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 13,
                  color: bold
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                  fontWeight:
                  bold ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: bold ? 16 : 13,
                  fontWeight:
                  bold ? FontWeight.bold : FontWeight.w600,
                  color: bold
                      ? AppColors.primary
                      : AppColors.textPrimary)),
        ],
      ),
    );
  }
}