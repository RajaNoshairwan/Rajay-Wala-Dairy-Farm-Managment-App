import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../services/order_service.dart';

class CartItem {
  final ProductModel product;
  double quantityLitres;
  CartItem({required this.product, this.quantityLitres = 1});

  double get amount => product.pricePerLitre * quantityLitres;
}

class CartViewModel extends ChangeNotifier {
  final List<CartItem> _items = [];
  final OrderService _orderService = OrderService();

  List<CartItem> get items => List.unmodifiable(_items);
  double get total => _items.fold(0, (s, e) => s + e.amount);
  bool get isEmpty => _items.isEmpty;

  void addProduct(ProductModel p) {
    final existing =
    _items.where((i) => i.product.productId == p.productId);
    if (existing.isNotEmpty) {
      existing.first.quantityLitres += 1;
    } else {
      _items.add(CartItem(product: p));
    }
    notifyListeners();
  }

  void remove(CartItem item) {
    _items.remove(item);
    notifyListeners();
  }

  void updateQuantity(CartItem item, double litres) {
    item.quantityLitres = litres;
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Future<String> placeOrder({
    required String customerId,
    required DeliveryAddress address,
    required String instructions,
    required double tip,
  }) async {
    final orderItems = _items
        .map((i) => OrderItem(
      productId: i.product.productId,
      productName: i.product.name,
      quantityLitres: i.quantityLitres,
      pricePerLitre: i.product.pricePerLitre,
    ))
        .toList();

    final order = OrderModel(
      orderId: '',
      customerId: customerId,
      items: orderItems,
      totalAmount: total + tip,
      status: 'pending',
      deliveryAddress: address.fullAddress,
      lat: address.lat,
      lng: address.lng,
      instructions: instructions,
      tip: tip,
      paymentMethod: 'COD',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final id = await _orderService.createOrder(order);
    clear();
    return id;
  }
}