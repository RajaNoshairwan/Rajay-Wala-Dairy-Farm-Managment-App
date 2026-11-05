class ProductModel {
  final String productId;
  final String name;
  final String description;
  final String imageUrl;
  final double pricePerLitre;
  final bool available;
  final List<String> sizes;

  ProductModel({
    required this.productId,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.pricePerLitre,
    this.available = true,
    this.sizes = const ['1L'],
  });

  factory ProductModel.fromMap(String id, Map<String, dynamic> map) {
    return ProductModel(
      productId: id,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      pricePerLitre: (map['pricePerLitre'] ?? 0).toDouble(),
      available: map['available'] ?? true,
      sizes: List<String>.from(map['sizes'] ?? ['1L']),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'pricePerLitre': pricePerLitre,
    'available': available,
    'sizes': sizes,
  };
}