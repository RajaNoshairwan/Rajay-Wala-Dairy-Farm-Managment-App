import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../models/product_model.dart';
import '../../../viewmodels/product_viewmodel.dart';

class AdminProductScreen extends StatelessWidget {
  const AdminProductScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ProductViewModel>();

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.add, color: Colors.green),
              title: const Text('Add New Product'),
              onTap: () => _showForm(context, vm, null),
            ),
          ),
          const SizedBox(height: 12),
          ...vm.products.map(
                (p) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(p.name),
                subtitle: Text(
                    '${CurrencyFormatter.format(p.pricePerLitre)} / L · ${p.available ? "Available" : "Unavailable"}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () => _showForm(context, vm, p),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => vm.delete(p.productId),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showForm(
      BuildContext context, ProductViewModel vm, ProductModel? existing) {
    final name = TextEditingController(text: existing?.name ?? '');
    final desc =
    TextEditingController(text: existing?.description ?? '');
    final price = TextEditingController(
        text: existing?.pricePerLitre.toString() ?? '');
    final image =
    TextEditingController(text: existing?.imageUrl ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(existing == null ? 'New Product' : 'Edit Product'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomTextField(controller: name, label: 'Name'),
              const SizedBox(height: 8),
              CustomTextField(
                  controller: desc, label: 'Description', maxLines: 2),
              const SizedBox(height: 8),
              CustomTextField(
                  controller: price,
                  label: 'Price per Litre',
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              CustomTextField(
                  controller: image, label: 'Image URL (optional)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          CustomButton(
            label: 'Save',
            onPressed: () async {
              final p = ProductModel(
                productId: existing?.productId ?? '',
                name: name.text.trim(),
                description: desc.text.trim(),
                imageUrl: image.text.trim(),
                pricePerLitre:
                double.tryParse(price.text) ?? 0,
                available: true,
              );
              if (existing == null) {
                await vm.add(p);
              } else {
                await vm.update(p);
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}