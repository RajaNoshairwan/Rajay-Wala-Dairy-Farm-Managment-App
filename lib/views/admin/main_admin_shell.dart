import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../admin/dashboard/admin_dashboard_screen.dart';
import '../admin/customers/customer_list_screen.dart';
import '../admin/orders/admin_order_list_screen.dart';
import '../admin/deliveries/delivery_schedule_screen.dart';
import '../admin/billing/admin_billing_screen.dart';
import '../admin/payments/admin_payment_screen.dart';
import '../admin/products/admin_product_screen.dart';
import '../admin/reports/reports_screen.dart';
import '../admin/notifications/admin_notification_screen.dart';
import '../admin/subscriptions/admin_subscriptions_screen.dart';

class MainAdminShell extends StatefulWidget {
  const MainAdminShell({super.key});
  @override
  State<MainAdminShell> createState() => _MainAdminShellState();
}

class _MainAdminShellState extends State<MainAdminShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _index = 0;

  final _screens = const [
    AdminDashboardScreen(),
    AdminOrderListScreen(),
    AdminBillingScreen(),
    CustomerListScreen(),
    DeliveryScheduleScreen(),
    AdminSubscriptionsScreen(),
    AdminPaymentScreen(),
    AdminProductScreen(),
    ReportsScreen(),
    AdminNotificationScreen(),
  ];

  final _titles = const [
    'Dashboard', 'Orders', 'Billing', 'Customers', 'Deliveries',
    'Subscriptions', 'Payments', 'Products', 'Reports', 'Notifications',
  ];

  final _icons = const [
    Icons.dashboard, Icons.receipt_long, Icons.request_quote,
    Icons.people, Icons.delivery_dining, Icons.autorenew,
    Icons.payments, Icons.inventory, Icons.bar_chart, Icons.notifications,
  ];

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Logout',
                  style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok == true && mounted) {
      await context.read<AuthViewModel>().signOut();
      if (!mounted) return;
      Navigator.of(context).popUntil((r) => r.isFirst);
    }
  }

  void _onBottomTap(int i) {
    if (i == 4) {
      _scaffoldKey.currentState?.openDrawer();
      return;
    }
    setState(() => _index = i);
  }

  @override
  Widget build(BuildContext context) {
    final bottomSelected = _index < 4 ? _index : 4;
    final topInset = MediaQuery.of(context).padding.top;
    final adminEmail =
        context.watch<AuthViewModel>().profile?.email ?? '';

    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: Text(_titles[_index]),
          actions: [
            IconButton(
                icon: const Icon(Icons.logout), onPressed: _confirmLogout),
          ],
        ),
        drawer: Drawer(
          backgroundColor: Colors.white,
          child: Column(
            children: [
              // ─── Full-width opaque header ────────────────
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, topInset + 20, 20, 20),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.admin_panel_settings,
                        color: Colors.white, size: 44),
                    const SizedBox(height: 8),
                    const Text(
                      'Admin Panel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      adminEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),

              // ─── Scrollable nav list ─────────────────────
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: List.generate(_titles.length, (i) {
                    return ListTile(
                      leading: Icon(_icons[i]),
                      title: Text(_titles[i]),
                      selected: i == _index,
                      selectedTileColor:
                      AppColors.primary.withValues(alpha: 0.1),
                      onTap: () {
                        setState(() => _index = i);
                        Navigator.pop(context);
                      },
                    );
                  }),
                ),
              ),

              // ─── Pinned footer logout ────────────────────
              const Divider(height: 1),
              ListTile(
                leading:
                const Icon(Icons.logout, color: AppColors.error),
                title: const Text('Logout',
                    style: TextStyle(color: AppColors.error)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmLogout();
                },
              ),
              SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
            ],
          ),
        ),
        body: _screens[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: bottomSelected,
          onDestinationSelected: _onBottomTap,
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.receipt_long_outlined),
                selectedIcon: Icon(Icons.receipt_long),
                label: 'Orders'),
            NavigationDestination(
                icon: Icon(Icons.request_quote_outlined),
                selectedIcon: Icon(Icons.request_quote),
                label: 'Billing'),
            NavigationDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: 'Customers'),
            NavigationDestination(
                icon: Icon(Icons.menu), label: 'More'),
          ],
        ),
      ),
    );
  }
}