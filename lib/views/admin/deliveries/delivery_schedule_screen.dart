import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/delivery_record_model.dart';
import '../../../services/delivery_service.dart';

class DeliveryScheduleScreen extends StatefulWidget {
  const DeliveryScheduleScreen({super.key});
  @override
  State<DeliveryScheduleScreen> createState() => _State();
}

class _State extends State<DeliveryScheduleScreen> {
  final _service = DeliveryService();
  final _timeFmt = DateFormat('hh:mm a');
  DateTime _selected = DateTime.now();
  List<DeliveryRecordModel> _records = [];
  Map<String, String> _names = {};
  bool _loading = false;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _records = await _service.getDeliveriesForDate(_selected);
      final snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').get();
      _names = {for (var d in snap.docs) d.id: (d.data()['name'] ?? '') as String};
    } catch (e) { debugPrint('Load: $e'); }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.calendar_today),
              label: Text(AppDateUtils.formatDate(_selected)),
              onPressed: () async {
                final d = await showDatePicker(context: context, initialDate: _selected, firstDate: DateTime(2024), lastDate: DateTime(2030));
                if (d != null) { setState(() => _selected = d); _load(); }
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () async {
              final created = await _service.generateDeliveriesForDate(_selected);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Generated $created records')));
              _load();
            },
            icon: const Icon(Icons.add),
          ),
        ]),
      ),
      Expanded(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _records.isEmpty
            ? const Center(child: Text('No deliveries for this date'))
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: _records.length,
          itemBuilder: (context, i) {
            final r = _records[i];
            final name = _names[r.customerId] ?? r.customerId;
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: r.status == 'delivered' ? Colors.green : Colors.orange,
                  child: Text('${r.quantityDelivered}L', style: const TextStyle(fontSize: 11, color: Colors.white)),
                ),
                title: Text(name),
                subtitle: Text(
                  '${AppDateUtils.formatDate(r.date)} · ${_timeFmt.format(r.recordedAt)}\nAmount: ${CurrencyFormatter.format(r.amount)} · ${r.status}',
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
    ]);
  }
}