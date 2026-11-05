import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../viewmodels/cart_viewmodel.dart';
import '../../../viewmodels/product_viewmodel.dart';
import 'product_detail_screen.dart';
import '../cart/cart_screen.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final products = context.watch<ProductViewModel>();
    final cart = context.watch<CartViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const CartScreen()),
                ),
              ),
              if (cart.items.isNotEmpty)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Text('${cart.items.length}',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 10)),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: products.loading
          ? const Center(child: CircularProgressIndicator())
          : products.products.isEmpty
          ? const EmptyState(
          message: 'No products available',
          icon: Icons.local_drink_outlined)
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: products.products.length,
        itemBuilder: (context, i) {
          final p = products.products[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      ProductDetailScreen(product: p),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: p.imageUrl.isEmpty
                          ? const Icon(Icons.local_drink,
                          size: 36,
                          color: AppColors.primary)
                          : ClipRRect(
                        borderRadius:
                        BorderRadius.circular(12),
                        child: Image.network(
                            p.imageUrl,
                            fit: BoxFit.cover),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(p.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight:
                                  FontWeight.bold)),
                          Text(p.description,
                              maxLines: 2,
                              overflow:
                              TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: AppColors
                                      .textSecondary)),
                          const SizedBox(height: 4),
                          Text(
                              CurrencyFormatter.format(
                                  p.pricePerLitre) +
                                  ' / L',
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight:
                                  FontWeight.w600)),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle,
                          color: AppColors.primary, size: 32),
                      onPressed: () {
                        context
                            .read<CartViewModel>()
                            .addProduct(p);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(
                          content:
                          Text('${p.name} added to cart'),
                          duration:
                          const Duration(seconds: 1),
                        ));
                      },
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}