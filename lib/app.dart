// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
//
// import 'core/constants/app_colors.dart';
// import 'viewmodels/auth_viewmodel.dart';
// import 'views/auth/login_screen.dart';
// import 'views/customer/main_customer_shell.dart';
// import 'views/admin/main_admin_shell.dart';
//
// class MilkDeliveryApp extends StatelessWidget {
//   const MilkDeliveryApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'Milk Delivery',
//       debugShowCheckedModeBanner: false,
//       theme: ThemeData(
//         useMaterial3: true,
//         primaryColor: AppColors.primary,
//         colorScheme: ColorScheme.fromSeed(
//           seedColor: AppColors.primary,
//           brightness: Brightness.light,
//         ),
//         scaffoldBackgroundColor: AppColors.background,
//         appBarTheme: const AppBarTheme(
//           elevation: 0,
//           centerTitle: true,
//           backgroundColor: AppColors.primary,
//           foregroundColor: Colors.white,
//         ),
//         inputDecorationTheme: InputDecorationTheme(
//           filled: true,
//           fillColor: Colors.white,
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(12),
//             borderSide: BorderSide(color: Colors.grey.shade300),
//           ),
//         ),
//       ),
//       home: Consumer<AuthViewModel>(
//         builder: (context, authVM, _) {
//           if (authVM.user == null) {
//             return const LoginScreen();
//           }
//           if (authVM.isAdmin) {
//             return const MainAdminShell();
//           }
//           return const MainCustomerShell();
//         },
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_colors.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'views/auth/login_screen.dart';
import 'views/customer/main_customer_shell.dart';
import 'views/admin/main_admin_shell.dart';

class MilkDeliveryApp extends StatelessWidget {
  const MilkDeliveryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Milk Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      home: Consumer<AuthViewModel>(
        builder: (context, authVM, _) {
          // Show splash while Firebase Auth is resolving the initial state
          if (!authVM.initialized) {
            return const _SplashScreen();
          }
          if (authVM.user == null) {
            return const LoginScreen();
          }
          if (authVM.isAdmin) {
            return const MainAdminShell();
          }
          return const MainCustomerShell();
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_drink, size: 90, color: Colors.white),
            SizedBox(height: 16),
            Text(
              'Rajay Wala Dairy Farm',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}