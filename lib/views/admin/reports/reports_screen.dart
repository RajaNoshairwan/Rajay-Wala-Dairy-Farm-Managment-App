import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/payment_model.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _State();
}

class _State extends State<ReportsScreen> {
  Map<String, String> _names = {};

  @override
  void initState() { super.initState(); _loadNames(); }

  Future<void> _loadNames() async {
    try {
      final snap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'customer').get();
      setState(() => _names = {for (var d in snap.docs) d.id: (d.data()['name'] ?? '') as String});
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('payments').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final payments = snap.data!.docs.map((d) => PaymentModel.fromMap(d.id, d.data())).toList()
          ..sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
        final total = payments.fold<double>(0, (s, p) => s + p.amount);
        final now = DateTime.now();
        final today = payments.where((p) =>
        p.paymentDate.year == now.year && p.paymentDate.month == now.month && p.paymentDate.day == now.day,
        ).fold<double>(0, (s, p) => s + p.amount);

        return ListView(padding: const EdgeInsets.all(16), children: [
          const Text('Reports', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _card("Today's Collection", CurrencyFormatter.format(today), Icons.today),
          const SizedBox(height: 8),
          _card('Total Collections', CurrencyFormatter.format(total), Icons.payments),
          const SizedBox(height: 16),
          const Text('Recent Payments', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...payments.take(15).map((p) => Card(
            child: ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: Text(_names[p.customerId] ?? p.customerId),
              subtitle: Text(AppDateUtils.formatDate(p.paymentDate)),
              trailing: Text(CurrencyFormatter.format(p.amount),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
            ),
          )),
        ]);
      },
    );
  }

  Widget _card(String label, String value, IconData icon) => Card(
    child: ListTile(
      leading: Icon(icon, color: AppColors.primary),
      title: Text(label),
      trailing: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    ),
  );
}