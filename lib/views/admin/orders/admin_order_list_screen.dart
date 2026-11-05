import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../viewmodels/admin_order_viewmodel.dart';

class AdminOrderListScreen extends StatefulWidget {
  const AdminOrderListScreen({super.key});
  @override
  State<AdminOrderListScreen> createState() => _State();
}

class _State extends State<AdminOrderListScreen> {
  final _fmt = DateFormat('dd MMM yyyy · hh:mm a');

  static const _statuses = ['all','pending','accepted','processing','outForDelivery','delivered','cancelled'];

  @override
  void initState() {
    super.initState();
    context.read<AdminOrderViewModel>().listen();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AdminOrderViewModel>();
    return Column(children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Row(children: _statuses.map((s) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(s), selected: vm.filter == s,
            onSelected: (_) => vm.setFilter(s),
          ),
        )).toList()),
      ),
      Expanded(
        child: vm.loading
            ? const Center(child: CircularProgressIndicator())
            : vm.orders.isEmpty
            ? const EmptyState(message: 'No orders')
            : ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: vm.orders.length,
          itemBuilder: (context, i) {
            final o = vm.orders[i];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Expanded(child: Text(vm.nameFor(o.customerId),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15))),
                    Chip(label: Text(o.status)),
                  ]),
                  Text(_fmt.format(o.createdAt), style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  const SizedBox(height: 4),
                  ...o.items.map((it) => Text('${it.productName} · ${it.quantityLitres}L')),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text('Total: ${CurrencyFormatter.format(o.totalAmount)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ]),
                  if (o.instructions.isNotEmpty)
                    Text('📝 ${o.instructions}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(spacing: 8, children: [
                    if (o.status == 'pending') ...[
                      FilledButton(onPressed: () => vm.updateStatus(o.orderId, 'accepted'), child: const Text('Accept')),
                      OutlinedButton(onPressed: () => vm.updateStatus(o.orderId, 'cancelled'),
                          child: const Text('Reject', style: TextStyle(color: AppColors.error))),
                    ],
                    if (o.status == 'accepted') FilledButton(onPressed: () => vm.updateStatus(o.orderId, 'processing'), child: const Text('Processing')),
                    if (o.status == 'processing') FilledButton(onPressed: () => vm.updateStatus(o.orderId, 'outForDelivery'), child: const Text('Out for Delivery')),
                    if (o.status == 'outForDelivery') FilledButton(onPressed: () => vm.updateStatus(o.orderId, 'delivered'), child: const Text('Mark Delivered')),
                  ]),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }
}