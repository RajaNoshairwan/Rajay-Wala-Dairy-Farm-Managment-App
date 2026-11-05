import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/subscription_viewmodel.dart';
import 'subscription_form_screen.dart';

class SubscriptionListScreen extends StatefulWidget {
  const SubscriptionListScreen({super.key});

  @override
  State<SubscriptionListScreen> createState() =>
      _SubscriptionListScreenState();
}

class _SubscriptionListScreenState extends State<SubscriptionListScreen> {
  @override
  void initState() {
    super.initState();
    final uid = context.read<AuthViewModel>().user?.uid;
    if (uid != null) {
      context.read<SubscriptionViewModel>().listenCustomer(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<SubscriptionViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('My Subscriptions')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New'),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SubscriptionFormScreen()),
        ),
      ),
      body: vm.loading
          ? const Center(child: CircularProgressIndicator())
          : vm.subscriptions.isEmpty
          ? const EmptyState(
          message: 'No subscriptions yet',
          icon: Icons.autorenew)
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: vm.subscriptions.length,
        itemBuilder: (context, i) {
          final s = vm.subscriptions[i];
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
                      Text('${s.quantityLitres}L · ${s.planType}',
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      Chip(
                        label: Text(s.status),
                        backgroundColor:
                        s.status == 'active'
                            ? Colors.green.shade100
                            : s.status == 'paused'
                            ? Colors.orange.shade100
                            : Colors.red.shade100,
                      ),
                    ],
                  ),
                  Text(
                      '${AppDateUtils.formatDate(s.startDate)} → ${AppDateUtils.formatDate(s.endDate)}'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (s.status == 'active')
                        OutlinedButton(
                          onPressed: () => context
                              .read<SubscriptionViewModel>()
                              .pause(
                              s,
                              DateTime.now(),
                              DateTime.now().add(
                                  const Duration(days: 7))),
                          child: const Text('Pause'),
                        ),
                      if (s.status == 'paused')
                        OutlinedButton(
                          onPressed: () => context
                              .read<SubscriptionViewModel>()
                              .resume(s),
                          child: const Text('Resume'),
                        ),
                      if (s.status != 'cancelled')
                        OutlinedButton(
                          onPressed: () => context
                              .read<SubscriptionViewModel>()
                              .cancel(s),
                          child: const Text('Cancel',
                              style: TextStyle(
                                  color: AppColors.error)),
                        ),
                      OutlinedButton(
                        onPressed: () => context
                            .read<SubscriptionViewModel>()
                            .skip(s, DateTime.now()
                            .add(const Duration(days: 1))),
                        child: const Text('Skip Tomorrow'),
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