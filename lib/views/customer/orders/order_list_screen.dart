import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../models/order_model.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/order_viewmodel.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid != null) {
      context.read<OrderViewModel>().listenCustomer(uid);
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return AppColors.warning;
      case 'accepted':
        return Colors.blue;
      case 'processing':
        return Colors.purple;
      case 'outForDelivery':
        return Colors.orange;
      case 'delivered':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OrderViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.orders.isEmpty
          ? const EmptyState(
          message: 'No orders yet',
          icon: Icons.receipt_long_outlined)
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: vm.orders.length,
        itemBuilder: (context, i) {
          final o = vm.orders[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(AppDateUtils.formatDate(
                          o.createdAt)),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(o.status)
                              .withValues(alpha: 0.15),
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        child: Text(o.status.toUpperCase(),
                            style: TextStyle(
                                color: _statusColor(o.status),
                                fontSize: 11,
                                fontWeight:
                                FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...o.items.map((it) => Text(
                      '${it.productName} · ${it.quantityLitres}L')),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment:
                    MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                          CurrencyFormatter.format(
                              o.totalAmount),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                      if (o.status == 'pending')
                        TextButton(
                          onPressed: () => context
                              .read<OrderViewModel>()
                              .cancel(o.orderId),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: AppColors.error)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}