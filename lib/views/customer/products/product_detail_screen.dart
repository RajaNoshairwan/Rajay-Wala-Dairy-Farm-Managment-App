import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../models/product_model.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../cart/cart_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(product.name)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: product.imageUrl.isEmpty
                  ? const Icon(Icons.local_drink,
                  size: 100, color: AppColors.primary)
                  : ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child:
                Image.network(product.imageUrl, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 16),
            Text(product.name,
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(product.description,
                style:
                const TextStyle(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Text(CurrencyFormatter.format(product.pricePerLitre) + ' / Litre',
                style: const TextStyle(
                    fontSize: 22,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            CustomButton(
              label: 'Add to Cart',
              icon: Icons.shopping_cart,
              onPressed: () {
                context.read<CartViewModel>().addProduct(product);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${product.name} added'),
                    action: SnackBarAction(
                      label: 'View Cart',
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const CartScreen()),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}