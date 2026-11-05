import 'package:flutter/material.dart';
import '../customer/home/customer_home_screen.dart';
import '../customer/products/product_list_screen.dart';
import '../customer/orders/order_list_screen.dart';
import '../customer/billing/bill_list_screen.dart';
import '../customer/profile/profile_screen.dart';

class MainCustomerShell extends StatefulWidget {
  const MainCustomerShell({super.key});
  @override
  State<MainCustomerShell> createState() => _MainCustomerShellState();
}

class _MainCustomerShellState extends State<MainCustomerShell> {
  int _index = 0;
  final _screens = const [
    CustomerHomeScreen(),
    ProductListScreen(),
    OrderListScreen(),
    BillListScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _index == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        setState(() => _index = 0);
      },
      child: Scaffold(
        body: _screens[_index],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.local_drink_outlined), selectedIcon: Icon(Icons.local_drink), label: 'Products'),
            NavigationDestination(icon: Icon(Icons.receipt_long_outlined), selectedIcon: Icon(Icons.receipt_long), label: 'Orders'),
            NavigationDestination(icon: Icon(Icons.payment_outlined), selectedIcon: Icon(Icons.payment), label: 'Bills'),
            NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}