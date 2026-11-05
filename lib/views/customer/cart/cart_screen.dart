import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../viewmodels/auth_viewmodel.dart';
import '../../../viewmodels/cart_viewmodel.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final _instructions = TextEditingController();
  final _tip = TextEditingController(text: '0');
  bool _placing = false;

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Cart')),
      body: cart.items.isEmpty
          ? const EmptyState(
          message: 'Your cart is empty',
          icon: Icons.shopping_cart_outlined)
          : Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                ...cart.items.map(
                      (item) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(item.product.name,
                                    style: const TextStyle(
                                        fontWeight:
                                        FontWeight.bold)),
                                Text(
                                    CurrencyFormatter.format(
                                        item.amount),
                                    style: const TextStyle(
                                        color:
                                        AppColors.primary)),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(
                                    Icons.remove_circle_outline),
                                onPressed: () {
                                  if (item.quantityLitres >
                                      1) {
                                    cart.updateQuantity(item,
                                        item.quantityLitres - 1);
                                  } else {
                                    cart.remove(item);
                                  }
                                },
                              ),
                              Text('${item.quantityLitres}L'),
                              IconButton(
                                icon: const Icon(
                                    Icons.add_circle_outline),
                                onPressed: () =>
                                    cart.updateQuantity(item,
                                        item.quantityLitres + 1),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _instructions,
                  label: 'Delivery Instructions (optional)',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                CustomTextField(
                  controller: _tip,
                  label: 'Tip (Rs)',
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold)),
                    Text(CurrencyFormatter.format(cart.total),
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 12),
                CustomButton(
                  label: 'Place Order (COD)',
                  loading: _placing,
                  onPressed: () async {
                    final authVM =
                    context.read<AuthViewModel>();
                    final profile = authVM.profile;
                    if (profile == null) return;
                    setState(() => _placing = true);
                    try {
                      await cart.placeOrder(
                        customerId: profile.uid,
                        address: profile.address,
                        instructions:
                        _instructions.text.trim(),
                        tip: double.tryParse(_tip.text) ?? 0,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(const SnackBar(
                          content: Text(
                              'Order placed successfully ✅'),
                        ));
                      }
                    } catch (e) {
                      setState(() => _placing = false);
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(
                          content:
                          Text('Error: $e')));
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}