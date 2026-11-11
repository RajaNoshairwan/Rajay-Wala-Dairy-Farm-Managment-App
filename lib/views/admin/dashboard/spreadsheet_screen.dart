import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../models/user_model.dart';
import '../../../models/delivery_record_model.dart';
import '../../../services/billing_service.dart';

class SpreadsheetScreen extends StatefulWidget {
  const SpreadsheetScreen({super.key});
  @override
  State<SpreadsheetScreen> createState() => _State();
}

class _State extends State<SpreadsheetScreen> {
  final _monthFmt = DateFormat('MMMM yyyy');
  final _billing = BillingService();
  DateTime _month = DateTime.now();
  List<UserModel> _customers = [];
  Map<String, Map<int, DeliveryRecordModel>> _records = {};
  bool _loading = true;

  // Compact layout
  static const double _dayColW = 24.0;
  static const double _custColW = 26.0; // narrow columns for 50+ customers
  static const double _totalColW = 40.0;
  static const double _rowH = 20.0;
  static const double _headerH = 32.0; // bottom total row height
  static const double _nameHeaderH = 80.0; // tall header for rotated names

  // Scroll controllers — outer header/body sync
  final _hHeaderCtrl = ScrollController();
  final _hBodyCtrl = ScrollController();
  final _vLeftCtrl = ScrollController();
  final _vBodyCtrl = ScrollController();
  bool _syncing = false;

  @override
  void initState() {
    super.initState();
    _hHeaderCtrl.addListener(() => _sync(_hHeaderCtrl, _hBodyCtrl));
    _hBodyCtrl.addListener(() => _sync(_hBodyCtrl, _hHeaderCtrl));
    _vLeftCtrl.addListener(() => _sync(_vLeftCtrl, _vBodyCtrl));
    _vBodyCtrl.addListener(() => _sync(_vBodyCtrl, _vLeftCtrl));
    _load();
  }

  @override
  void dispose() {
    _hHeaderCtrl.dispose();
    _hBodyCtrl.dispose();
    _vLeftCtrl.dispose();
    _vBodyCtrl.dispose();
    super.dispose();
  }

  void _sync(ScrollController from, ScrollController to) {
    if (_syncing) return;
    if (!from.hasClients || !to.hasClients) return;
    final max = to.position.maxScrollExtent;
    final target = from.offset.clamp(0.0, max);
    if ((to.offset - target).abs() < 0.5) return;
    _syncing = true;
    to.jumpTo(target);
    _syncing = false;
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();
      _customers = users.docs
          .map((d) => UserModel.fromMap(d.id, d.data()))
          .where((c) => !c.isDead) // hide dead customers
          .toList()
        ..sort((a, b) {
          // Sort by display name (nickname-aware)
          final an = a.nickname.isNotEmpty ? a.nickname : a.name;
          final bn = b.nickname.isNotEmpty ? b.nickname : b.name;
          return an.toLowerCase().compareTo(bn.toLowerCase());
        });

      final deliveries = await FirebaseFirestore.instance
          .collection('delivery_records')
          .get();
      final map = <String, Map<int, DeliveryRecordModel>>{};
      for (final d in deliveries.docs) {
        final r = DeliveryRecordModel.fromMap(d.id, d.data());
        if (r.date.year == _month.year && r.date.month == _month.month) {
          map.putIfAbsent(r.customerId, () => {})[r.date.day] = r;
        }
      }
      _records = map;
    } catch (e) {
      debugPrint('Spreadsheet load error: $e');
    }
    if (mounted) setState(() => _loading = false);
  }

  int get _daysInMonth => DateTime(_month.year, _month.month + 1, 0).day;

  /// Format preserving decimals — "5" for whole, "1.5" for decimal
  String _fmtNum(double v) {
    if (v == 0) return '';
    if (v == v.truncateToDouble()) return v.toInt().toString();
    final s = v.toString();
    return s;
  }

  Future<void> _editCell(UserModel customer, int day) async {
    final existing = _records[customer.uid]?[day];
    final qtyCtrl = TextEditingController(
        text: existing != null ? _fmtNum(existing.quantityDelivered) : '');
    final defaultRate =
    customer.ratePerKg > 0 ? customer.ratePerKg : 150.0;
    final rateCtrl = TextEditingController(
        text: _fmtNum(existing?.priceAtDelivery ?? defaultRate));

    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
            '${customer.displayName} · $day/${_month.month}/${_month.year}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: qtyCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                  labelText: 'Quantity (kg)',
                  helperText: 'Decimals allowed, leave blank to clear'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: rateCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              decoration:
              const InputDecoration(labelText: 'Rate per kg (Rs)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save')),
        ],
      ),
    );
    if (saved != true) return;

    final qty = double.tryParse(qtyCtrl.text) ?? 0.0;
    final rate = double.tryParse(rateCtrl.text) ?? 0.0;
    final recordId = existing?.recordId ??
        'MANUAL-$day-${_month.month}-${_month.year}-${customer.uid}';

    try {
      if (qty <= 0) {
        if (existing != null) {
          await FirebaseFirestore.instance
              .collection('delivery_records')
              .doc(recordId)
              .delete();
        }
      } else {
        await FirebaseFirestore.instance
            .collection('delivery_records')
            .doc(recordId)
            .set(DeliveryRecordModel(
          recordId: recordId,
          customerId: customer.uid,
          subscriptionId: existing?.subscriptionId ?? '',
          date: DateTime(_month.year, _month.month, day),
          quantityDelivered: qty,
          priceAtDelivery: rate,
          amount: qty * rate,
          status: 'delivered',
          recordedAt: DateTime.now(),
        ).toMap());
      }
      await _billing.recomputeOutstanding(customer.uid);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _copyFromDate(DateTime source) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Copy column'),
        content: Text(
            'Copy all quantities from ${DateFormat('dd MMM').format(source)} to today?\n\nExisting today values will be replaced.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Copy')),
        ],
      ),
    );
    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final srcStart = DateTime(source.year, source.month, source.day);
      final srcEnd = srcStart.add(const Duration(days: 1));
      final snap = await FirebaseFirestore.instance
          .collection('delivery_records')
          .where('date',
          isGreaterThanOrEqualTo: Timestamp.fromDate(srcStart))
          .where('date', isLessThan: Timestamp.fromDate(srcEnd))
          .get();

      final today = DateTime.now();
      final todayNormalized = DateTime(today.year, today.month, today.day);

      for (final doc in snap.docs) {
        final rec = DeliveryRecordModel.fromMap(doc.id, doc.data());
        if (rec.quantityDelivered <= 0) continue;
        final recordId =
            'COPY-${todayNormalized.year}-${todayNormalized.month}-${todayNormalized.day}-${rec.customerId}';
        await FirebaseFirestore.instance
            .collection('delivery_records')
            .doc(recordId)
            .set(DeliveryRecordModel(
          recordId: recordId,
          customerId: rec.customerId,
          subscriptionId: rec.subscriptionId,
          date: todayNormalized,
          quantityDelivered: rec.quantityDelivered,
          priceAtDelivery: rec.priceAtDelivery,
          amount: rec.quantityDelivered * rec.priceAtDelivery,
          status: 'delivered',
          recordedAt: DateTime.now(),
        ).toMap());
        await _billing.recomputeOutstanding(rec.customerId);
      }
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Copied ${snap.docs.length} entries'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _copyFromYesterday() async {
    final y = DateTime.now().subtract(const Duration(days: 1));
    await _copyFromDate(y);
  }

  Future<void> _copyFromPicker() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 1)),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (d != null) await _copyFromDate(d);
  }

  @override
  Widget build(BuildContext context) {
    final days = List<int>.generate(_daysInMonth, (i) => i + 1);

    return Scaffold(
      appBar: AppBar(title: const Text('Monthly Spreadsheet')),
      body: Column(
        children: [
          // Month nav
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: () {
                    setState(() =>
                    _month = DateTime(_month.year, _month.month - 1));
                    _load();
                  },
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Center(
                    child: Text(_monthFmt.format(_month),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    setState(() =>
                    _month = DateTime(_month.year, _month.month + 1));
                    _load();
                  },
                  icon: const Icon(Icons.chevron_right),
                ),
                IconButton(
                  onPressed: _load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
          ),

          // Copy buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.content_copy, size: 16),
                    label: const Text('Copy Yesterday',
                        style: TextStyle(fontSize: 12)),
                    onPressed: _copyFromYesterday,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: const Text('Copy From Date',
                        style: TextStyle(fontSize: 12)),
                    onPressed: _copyFromPicker,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Frozen grid
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _customers.isEmpty
                ? const Center(child: Text('No live customers'))
                : _buildGrid(days),
          ),

          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            color: Colors.grey.shade100,
            child: Text(
              'Rows = days · Columns = customers. '
                  'Tap any cell to edit · tap a name to see it in full.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  /// Rotated customer-name header cell (reads bottom → top).
  /// Tap to see the full name in a dialog.
  Widget _nameHeaderCell(UserModel c) {
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(c.displayName),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
      child: Container(
        width: _custColW,
        height: _nameHeaderH,
        decoration: BoxDecoration(
          color: AppColors.primary,
          border: Border.all(color: Colors.white24, width: 0.5),
        ),
        child: RotatedBox(
          quarterTurns: 3, // text reads bottom → top
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                c.displayName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    height: 1.1),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(List<int> days) {
    return Column(
      children: [
        // ── Frozen header row (customer names, rotated) ─────
        SizedBox(
          height: _nameHeaderH,
          child: Row(
            children: [
              // top-left corner
              Container(
                width: _dayColW,
                height: _nameHeaderH,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  border: Border.all(color: Colors.white24, width: 0.5),
                ),
                child: const Center(
                  child: Text('Day',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10)),
                ),
              ),
              // customer headers (horizontal scroll, synced with body)
              Expanded(
                child: SingleChildScrollView(
                  controller: _hHeaderCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: Row(
                    children: [
                      for (final c in _customers) _nameHeaderCell(c),
                      Container(
                        width: _totalColW,
                        height: _nameHeaderH,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          border:
                          Border.all(color: Colors.white24, width: 0.5),
                        ),
                        child: const Center(
                          child: Text('Total',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Body ───────────────────────────────────────────
        Expanded(
          child: Row(
            children: [
              // Frozen day column (vertical scroll synced with body)
              SizedBox(
                width: _dayColW,
                child: SingleChildScrollView(
                  controller: _vLeftCtrl,
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: [
                      for (final d in days)
                        Container(
                          width: _dayColW,
                          height: _rowH,
                          padding:
                          const EdgeInsets.symmetric(horizontal: 6),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            border: Border.all(
                                color: Colors.grey.shade300, width: 0.5),
                          ),
                          child: Text('$d',
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600)),
                        ),
                      // Aligns with grand-total row at body bottom
                      Container(
                        width: _dayColW,
                        height: _headerH,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          border: Border.all(
                              color: Colors.grey.shade400, width: 0.5),
                        ),
                        child: const Text('Total',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              // Body grid (both axes scroll)
              Expanded(
                child: SingleChildScrollView(
                  controller: _hBodyCtrl,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  child: SingleChildScrollView(
                    controller: _vBodyCtrl,
                    physics: const ClampingScrollPhysics(),
                    child: Column(
                      children: [
                        for (final d in days) _dayRow(d),
                        _grandTotalRow(days),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _dayRow(int day) {
    double rowSum = 0.0;
    for (final c in _customers) {
      rowSum += _records[c.uid]?[day]?.quantityDelivered ?? 0.0;
    }
    return Row(
      children: [
        for (final c in _customers) _dataCell(c, day),
        Container(
          width: _totalColW,
          height: _rowH,
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Center(
            child: Text(
              rowSum > 0 ? _fmtNum(rowSum) : '',
              style:
              const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _dataCell(UserModel c, int day) {
    final rec = _records[c.uid]?[day];
    return GestureDetector(
      onTap: () => _editCell(c, day),
      child: Container(
        width: _custColW,
        height: _rowH,
        decoration: BoxDecoration(
          color: rec != null
              ? AppColors.primary.withValues(alpha: 0.08)
              : Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 0.5),
        ),
        child: Center(
          child: Text(
            rec != null ? _fmtNum(rec.quantityDelivered) : '',
            style: TextStyle(
              fontSize: 10,
              fontWeight: rec != null ? FontWeight.bold : FontWeight.normal,
              color: rec != null ? AppColors.primary : Colors.grey.shade400,
            ),
          ),
        ),
      ),
    );
  }

  Widget _grandTotalRow(List<int> days) {
    return Row(
      children: [
        for (final c in _customers)
          Container(
            width: _custColW,
            height: _headerH,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              border: Border.all(color: Colors.grey.shade400, width: 0.5),
            ),
            child: Center(
              child: () {
                final recs = _records[c.uid] ?? {};
                final total = recs.values.fold<double>(
                    0.0, (s, r) => s + r.quantityDelivered);
                return Text(
                  total > 0 ? _fmtNum(total) : '—',
                  style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary),
                );
              }(),
            ),
          ),
        Container(
          width: _totalColW,
          height: _headerH,
          decoration: BoxDecoration(
            color: AppColors.primary,
            border: Border.all(color: Colors.grey.shade400, width: 0.5),
          ),
          child: Center(
            child: () {
              double grand = 0.0;
              for (final c in _customers) {
                final recs = _records[c.uid] ?? {};
                grand += recs.values.fold<double>(
                    0.0, (s, r) => s + r.quantityDelivered);
              }
              return Text(
                _fmtNum(grand),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              );
            }(),
          ),
        ),
      ],
    );
  }
}