import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/delivery_record_model.dart';
import '../../../services/billing_service.dart';
import '../../../services/delivery_service.dart';

class CustomerDeliveryRecordsScreen extends StatefulWidget {
  final String customerId;
  final String customerName;
  const CustomerDeliveryRecordsScreen({super.key, required this.customerId, required this.customerName});
  @override
  State<CustomerDeliveryRecordsScreen> createState() => _State();
}

class _State extends State<CustomerDeliveryRecordsScreen> {
  final _service = DeliveryService();
  final _billing = BillingService();
  final _monthFmt = DateFormat('MMMM yyyy');
  DateTime _month = DateTime.now();
  List<DeliveryRecordModel> _records = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _service.getRecordsForCustomer(widget.customerId);
      _records = all.where((r) => r.date.year == _month.year && r.date.month == _month.month).toList()
        ..sort((a, b) => a.date.compareTo(b.date));
    } catch (e) { debugPrint('Load: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  String _key(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _addOrEdit({DeliveryRecordModel? existing}) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _RecordDialog(initial: existing, defaultDate: existing?.date ?? DateTime(_month.year, _month.month, DateTime.now().day)),
    );
    if (result == null) return;
    final date = result['date'] as DateTime;
    final qty = result['qty'] as double;
    final price = result['price'] as double;
    final status = result['status'] as String;
    final recordId = existing?.recordId ?? 'MANUAL-${_key(date)}-${widget.customerId}';
    try {
      await _service.recordDelivery(DeliveryRecordModel(
        recordId: recordId,
        customerId: widget.customerId,
        subscriptionId: existing?.subscriptionId ?? '',
        date: DateTime(date.year, date.month, date.day),
        quantityDelivered: qty,
        priceAtDelivery: price,
        amount: qty * price,
        status: status,
        recordedAt: DateTime.now(),
      ));
      await _billing.recomputeOutstanding(widget.customerId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _delete(String id) async {
    try {
      await _service.deleteRecord(id);
      await _billing.recomputeOutstanding(widget.customerId);
      _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalQty = _records.fold<double>(0, (s, r) => s + r.quantityDelivered);
    final totalAmount = _records.fold<double>(0, (s, r) => s + r.amount);
    return Scaffold(
      appBar: AppBar(title: Text(widget.customerName)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addOrEdit(),
        icon: const Icon(Icons.add),
        label: const Text('Add Record'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            IconButton(onPressed: () { setState(() => _month = DateTime(_month.year, _month.month - 1)); _load(); }, icon: const Icon(Icons.chevron_left)),
            Expanded(child: Center(child: Text(_monthFmt.format(_month), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)))),
            IconButton(onPressed: () { setState(() => _month = DateTime(_month.year, _month.month + 1)); _load(); }, icon: const Icon(Icons.chevron_right)),
          ]),
        ),
        Card(
          margin: const EdgeInsets.symmetric(horizontal: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _stat('Days', '${_records.length}'),
              _stat('Qty', '${totalQty.toStringAsFixed(1)}L'),
              _stat('Amount', CurrencyFormatter.format(totalAmount)),
            ]),
          ),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _records.isEmpty
              ? const Center(child: Text('No records this month'))
              : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _records.length,
            itemBuilder: (context, i) {
              final r = _records[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: r.status == 'delivered' ? Colors.green : Colors.orange,
                    child: Text('${r.quantityDelivered}L', style: const TextStyle(fontSize: 11, color: Colors.white)),
                  ),
                  title: Text(AppDateUtils.formatDate(r.date)),
                  subtitle: Text('${CurrencyFormatter.format(r.priceAtDelivery)}/L · Amount: ${CurrencyFormatter.format(r.amount)}'),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(icon: const Icon(Icons.edit), onPressed: () => _addOrEdit(existing: r)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _delete(r.recordId)),
                  ]),
                ),
              );
            },
          ),
        ),
      ]),
    );
  }

  Widget _stat(String label, String value) => Column(children: [
    Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
    const SizedBox(height: 4),
    Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primary)),
  ]);
}

class _RecordDialog extends StatefulWidget {
  final DeliveryRecordModel? initial;
  final DateTime defaultDate;
  const _RecordDialog({this.initial, required this.defaultDate});
  @override
  State<_RecordDialog> createState() => _RecordDialogState();
}

class _RecordDialogState extends State<_RecordDialog> {
  late DateTime _date;
  late final TextEditingController _qty;
  late final TextEditingController _price;
  late String _status;

  @override
  void initState() {
    super.initState();
    _date = widget.initial?.date ?? widget.defaultDate;
    _qty = TextEditingController(text: widget.initial?.quantityDelivered.toString() ?? '1');
    _price = TextEditingController(text: widget.initial?.priceAtDelivery.toString() ?? '150');
    _status = widget.initial?.status ?? 'delivered';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initial == null ? 'Add Delivery Record' : 'Edit Record'),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          OutlinedButton.icon(
            onPressed: () async {
              final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2024), lastDate: DateTime(2030));
              if (d != null) setState(() => _date = d);
            },
            icon: const Icon(Icons.calendar_today),
            label: Text(AppDateUtils.formatDate(_date)),
          ),
          const SizedBox(height: 8),
          TextField(controller: _qty, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Quantity (litres)')),
          const SizedBox(height: 8),
          TextField(controller: _price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Price per litre')),
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
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {
            'date': _date,
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