// //
// // import 'package:flutter/material.dart';
// // import 'package:firebase_core/firebase_core.dart';
// // import 'firebase_options.dart';
// //
// // void main() async {
// //   WidgetsFlutterBinding.ensureInitialized();
// //
// //   try {
// //     await Firebase.initializeApp(
// //       options: DefaultFirebaseOptions.currentPlatform,
// //     );
// //
// //     runApp(const MyApp());
// //   } catch (e) {
// //     runApp(MyApp(error: e.toString()));
// //   }
// // }
// //
// // class MyApp extends StatelessWidget {
// //   final String? error;
// //
// //   const MyApp({super.key, this.error});
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     final isInitialized = Firebase.apps.isNotEmpty && error == null;
// //
// //     return MaterialApp(
// //       debugShowCheckedModeBanner: false,
// //       home: Scaffold(
// //         appBar: AppBar(title: const Text('Firebase Test')),
// //         body: Center(
// //           child: error != null
// //               ? Text('Firebase Error:\n$error')
// //               : Text(
// //             isInitialized
// //                 ? 'Firebase Initialized Successfully!'
// //                 : 'Firebase Not Initialized',
// //             textAlign: TextAlign.center,
// //             style: const TextStyle(fontSize: 20),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
// import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart';
// import 'package:provider/provider.dart';
//
// import 'firebase_options.dart';
// import 'app.dart';
// import 'viewmodels/auth_viewmodel.dart';
// import 'viewmodels/product_viewmodel.dart';
// import 'viewmodels/cart_viewmodel.dart';
// import 'viewmodels/order_viewmodel.dart';
// import 'viewmodels/subscription_viewmodel.dart';
// import 'viewmodels/billing_viewmodel.dart';
// import 'viewmodels/admin_dashboard_viewmodel.dart';
// import 'viewmodels/admin_customer_viewmodel.dart';
// import 'viewmodels/admin_order_viewmodel.dart';
// import 'viewmodels/admin_billing_viewmodel.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Firebase.initializeApp(
//     options: DefaultFirebaseOptions.currentPlatform,
//   );
//
//   runApp(
//     MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => AuthViewModel()),
//         ChangeNotifierProvider(create: (_) => ProductViewModel()),
//         ChangeNotifierProvider(create: (_) => CartViewModel()),
//         ChangeNotifierProvider(create: (_) => OrderViewModel()),
//         ChangeNotifierProvider(create: (_) => SubscriptionViewModel()),
//         ChangeNotifierProvider(create: (_) => BillingViewModel()),
//         ChangeNotifierProvider(create: (_) => AdminDashboardViewModel()),
//         ChangeNotifierProvider(create: (_) => AdminCustomerViewModel()),
//         ChangeNotifierProvider(create: (_) => AdminOrderViewModel()),
//         ChangeNotifierProvider(create: (_) => AdminBillingViewModel()),
//       ],
//       child: const MilkDeliveryApp(),
//     ),
//   );
// }



import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'app.dart';
import 'services/permission_service.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/product_viewmodel.dart';
import 'viewmodels/cart_viewmodel.dart';
import 'viewmodels/order_viewmodel.dart';
import 'viewmodels/subscription_viewmodel.dart';
import 'viewmodels/billing_viewmodel.dart';
import 'viewmodels/admin_dashboard_viewmodel.dart';
import 'viewmodels/admin_customer_viewmodel.dart';
import 'viewmodels/admin_order_viewmodel.dart';
import 'viewmodels/admin_billing_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthViewModel()),
      ChangeNotifierProvider(create: (_) => ProductViewModel()),
      ChangeNotifierProvider(create: (_) => CartViewModel()),
      ChangeNotifierProvider(create: (_) => OrderViewModel()),
      ChangeNotifierProvider(create: (_) => SubscriptionViewModel()),
      ChangeNotifierProvider(create: (_) => BillingViewModel()),
      ChangeNotifierProvider(create: (_) => AdminDashboardViewModel()),
      ChangeNotifierProvider(create: (_) => AdminCustomerViewModel()),
      ChangeNotifierProvider(create: (_) => AdminOrderViewModel()),
      ChangeNotifierProvider(create: (_) => AdminBillingViewModel()),
    ],
    child: const MilkDeliveryApp(),
  ));
  WidgetsBinding.instance.addPostFrameCallback((_) {
    PermissionService.requestInitialPermissions();
  });
}