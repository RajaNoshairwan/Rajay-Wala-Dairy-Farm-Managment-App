import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../models/subscription_model.dart';
import 'admin_subscription_detail_screen.dart';

class AdminSubscriptionsScreen extends StatefulWidget {
  const AdminSubscriptionsScreen({super.key});
  @override
  State<AdminSubscriptionsScreen> createState() => _State();
}

class _State extends State<AdminSubscriptionsScreen> {
  String _filter = 'active';
  Map<String, String> _names = {};
  Map<String, String> _products = {};

  @override
  void initState() {
    super.initState();
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    try {
      final users = await FirebaseFirestore.instance
          .collection('users')
          .where('role', isEqualTo: 'customer')
          .get();
      final prods =
      await FirebaseFirestore.instance.collection('products').get();
      if (!mounted) return;
      setState(() {
        _names = {
          for (var d in users.docs)
            d.id: (d.data()['name'] ?? '') as String
        };
        _products = {
          for (var d in prods.docs)
            d.id: (d.data()['name'] ?? '') as String
        };
      });
    } catch (e) {
      debugPrint('Lookup error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.all(12),
          child: Row(
            children: ['active', 'paused', 'cancelled', 'expired']
                .map((s) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(s),
                selected: _filter == s,
                onSelected: (_) => setState(() => _filter = s),
              ),
            ))
                .toList(),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('subscriptions')
                .snapshots(),
            builder: (context, snap) {
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final all = snap.data!.docs
                  .map((d) => SubscriptionModel.fromMap(d.id, d.data()))
                  .toList();
              final filtered = all
                  .where((s) => _filter == 'all' || s.status == _filter)
                  .toList()
                ..sort((a, b) => b.startDate.compareTo(a.startDate));
              if (filtered.isEmpty) {
                return Center(child: Text('No $_filter subscriptions'));
              }
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: filtered.length,
                itemBuilder: (context, i) {
                  final s = filtered[i];
                  final name = _names[s.customerId] ?? s.customerId;
                  final product = _products[s.productId] ?? s.productId;
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: s.status == 'active'
                            ? Colors.green
                            : Colors.orange,
                        child: const Icon(Icons.autorenew,
                            color: Colors.white, size: 18),
                      ),
                      title: Text('$name · ${s.quantityLitres}L $product'),
                      subtitle: Text(
                          '${AppDateUtils.formatDate(s.startDate)} → ${AppDateUtils.formatDate(s.endDate)}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Chip(
                            label: Text(s.status),
                            backgroundColor: s.status == 'active'
                                ? Colors.green.shade100
                                : s.status == 'paused'
                                ? Colors.orange.shade100
                                : Colors.red.shade100,
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AdminSubscriptionDetailScreen(
                            subscription: s,
                            customerName: name,
                            productName: product,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}