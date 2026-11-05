import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/subscription_model.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/product_viewmodel.dart';
import '../../../viewmodels/subscription_viewmodel.dart';

class SubscriptionFormScreen extends StatefulWidget {
  const SubscriptionFormScreen({super.key});

  @override
  State<SubscriptionFormScreen> createState() =>
      _SubscriptionFormScreenState();
}

class _SubscriptionFormScreenState extends State<SubscriptionFormScreen> {
  String? _productId;
  double _qty = 1;
  String _planType = 'monthly';
  bool _skipSundays = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('New Subscription')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Product',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _productId,
              items: products.products
                  .map((p) => DropdownMenuItem(
                  value: p.productId, child: Text(p.name)))
                  .toList(),
              onChanged: (v) => setState(() => _productId = v),
              decoration:
              const InputDecoration(labelText: 'Select product'),
            ),
            const SizedBox(height: 16),
            const Text('Daily Quantity (Litres)',
                style: TextStyle(fontWeight: FontWeight.bold)),
            Slider(
              value: _qty,
              min: 0.5,
              max: 5,
              divisions: 9,
              label: '${_qty}L',
              onChanged: (v) => setState(() => _qty = v),
            ),
            Text('${_qty}L per day'),
            const SizedBox(height: 16),
            const Text('Plan Type',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'daily', label: Text('Daily')),
                ButtonSegment(value: 'weekly', label: Text('Weekly')),
                ButtonSegment(value: 'monthly', label: Text('Monthly')),
              ],
              selected: {_planType},
              onSelectionChanged: (s) =>
                  setState(() => _planType = s.first),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Skip Sundays'),
              value: _skipSundays,
              onChanged: (v) => setState(() => _skipSundays = v),
            ),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Create Subscription',
              loading: _saving,
              onPressed: _productId == null
                  ? null
                  : () async {
                final uid =
                    context.read<AuthViewModel>().user?.uid;
                if (uid == null) return;
                setState(() => _saving = true);
                final start = DateTime.now();
                final end = _planType == 'daily'
                    ? start.add(const Duration(days: 1))
                    : _planType == 'weekly'
                    ? start.add(const Duration(days: 7))
                    : DateTime(start.year, start.month + 1,
                    start.day);
                // Generate skip dates (next 60 days of Sundays)
                final skips = <DateTime>[];
                if (_skipSundays) {
                  for (int i = 0; i < 60; i++) {
                    final d = start.add(Duration(days: i));
                    if (d.weekday == DateTime.sunday) skips.add(d);
                  }
                }
                await context
                    .read<SubscriptionViewModel>()
                    .create(SubscriptionModel(
                  subscriptionId: '',
                  customerId: uid,
                  productId: _productId!,
                  quantityLitres: _qty,
                  planType: _planType,
                  startDate: start,
                  endDate: end,
                  skipDates: skips,
                ));
                if (mounted) Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}