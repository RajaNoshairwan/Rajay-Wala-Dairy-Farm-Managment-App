// import 'package:flutter/material.dart';
// import '../models/product_model.dart';
// import '../services/product_service.dart';
//
// class ProductViewModel extends ChangeNotifier {
//   final ProductService _service = ProductService();
//   List<ProductModel> _products = [];
//   bool _loading = false;
//
//   List<ProductModel> get products => _products;
//   bool get loading => _loading;
//
//   ProductViewModel() {
//     _service.watchProducts().listen((list) {
//       _products = list;
//       notifyListeners();
//     });
//   }
//
//   Future<void> add(ProductModel p) async {
//     _loading = true;
//     notifyListeners();
//     await _service.addProduct(p);
//     _loading = false;
//     notifyListeners();
//   }
//
//   Future<void> update(ProductModel p) async {
//     _loading = true;
//     notifyListeners();
//     await _service.updateProduct(p);
//     _loading = false;
//     notifyListeners();
//   }
//
//   Future<void> delete(String id) async {
//     await _service.deleteProduct(id);
//   }
// }




import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductViewModel extends ChangeNotifier {
  final ProductService _service = ProductService();
  List<ProductModel> _products = [];
  bool _loading = false;

  List<ProductModel> get products => _products;
  bool get loading => _loading;

  ProductViewModel() {
    _service.watchProducts().listen(
          (list) {
        _products = list;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Product stream error: $e');
      },
    );
  }

  Future<void> add(ProductModel p) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.addProduct(p);
    } catch (e) {
      debugPrint('Add product error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> update(ProductModel p) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.updateProduct(p);
    } catch (e) {
      debugPrint('Update product error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> delete(String id) async {
    try {
      await _service.deleteProduct(id);
    } catch (e) {
      debugPrint('Delete product error: $e');
    }
  }
}