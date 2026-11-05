import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<ProductModel>> watchProducts() {
    return _db
        .collection('products')
        .snapshots()
        .map((s) => s.docs
        .map((d) => ProductModel.fromMap(d.id, d.data()))
        .toList());
  }

  Future<List<ProductModel>> getProducts() async {
    final snap = await _db.collection('products').get();
    return snap.docs
        .map((d) => ProductModel.fromMap(d.id, d.data()))
        .toList();
  }

  Future<String> addProduct(ProductModel product) async {
    final ref = await _db.collection('products').add(product.toMap());
    return ref.id;
  }

  Future<void> updateProduct(ProductModel product) {
    return _db
        .collection('products')
        .doc(product.productId)
        .update(product.toMap());
  }

  Future<void> deleteProduct(String productId) {
    return _db.collection('products').doc(productId).delete();
  }
}