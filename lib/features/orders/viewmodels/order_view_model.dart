import 'package:flutter/material.dart';

import '../../../data/models/orders/order.dart';
import '../../../data/models/products/product.dart';
import '../../../data/models/tables/restaurant_table.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../models/product_selection.dart';

class OrderViewModel extends ChangeNotifier {
  OrderViewModel({
    required ProductRepository productRepository,
    required OrderRepository orderRepository,
    required TableRepository tableRepository,
    required AuthRepository authRepository,
  })  : _productRepository = productRepository,
        _orderRepository = orderRepository,
        _tableRepository = tableRepository,
        _authRepository = authRepository;

  final ProductRepository _productRepository;
  final OrderRepository _orderRepository;
  final TableRepository _tableRepository;
  final AuthRepository _authRepository;

  List<Product> products = [];
  Order? order;
  String selectedCategory = 'Todos';
  bool isLoading = false;
  bool isSending = false;
  bool isOrderExpanded = false;
  String? errorMessage;

  static const String allCategory = 'Todos';
  static const String mainCategory = 'Platillos';
  static const String drinksCategory = 'Bebidas';
  static const String extrasCategory = 'Extras';

  List<String> get categories => const [
    allCategory,
    mainCategory,
    drinksCategory,
    extrasCategory,
  ];

  List<Product> get filteredProducts {
    switch (selectedCategory) {
      case allCategory:
        return products;
      case mainCategory:
        return mainProducts;
      case drinksCategory:
        return beverageProducts;
      case extrasCategory:
        return extraProducts;
      default:
        return products;
    }
  }

  List<Product> get mainProducts =>
      products.where((product) => isPrimaryProduct(product)).toList();

  List<Product> get beverageProducts =>
      products.where((product) => _isBeverageCategory(product.category)).toList();

  List<Product> get extraProducts =>
      products.where((product) => _isExtraCategory(product.category)).toList();

  bool isPrimaryProduct(Product product) =>
      !_isBeverageCategory(product.category) &&
      !_isExtraCategory(product.category);

  Future<void> load(RestaurantTable table) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      products = await _productRepository.getProducts();
      order = await _orderRepository.getOpenOrderByTable(table.id);
      if (order == null) {
        final userId = _authRepository.currentUser?.userId;
        if (userId == null) throw Exception('No hay usuario autenticado.');
        await _tableRepository.openTable(table.id, userId);
        order = await _orderRepository.getOpenOrderByTable(table.id);
      }
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void selectCategory(String category) {
    selectedCategory = category;
    notifyListeners();
  }

  void toggleOrderExpanded() {
    isOrderExpanded = !isOrderExpanded;
    notifyListeners();
  }

  Future<void> addProduct(Product product, RestaurantTable table) async {
    if (order == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      order = await _orderRepository.addItem(
        orderId: order!.id,
        productId: product.id,
      );
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addProductWithSelections({
    required Product mainProduct,
    required int quantity,
    required RestaurantTable table,
    required List<ProductSelection> complements,
  }) async {
    if (order == null) return;
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _orderRepository.addItem(
        orderId: order!.id,
        productId: mainProduct.id,
        quantity: quantity,
      );

      for (final complement in complements) {
        if (complement.quantity <= 0) {
          continue;
        }
        await _orderRepository.addItem(
          orderId: order!.id,
          productId: complement.product.id,
          quantity: complement.quantity,
        );
      }

      order = await _orderRepository.getOpenOrderByTable(table.id);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendToKitchen(RestaurantTable table) async {
    if (order == null) return;
    isSending = true;
    errorMessage = null;
    notifyListeners();
    try {
      await _orderRepository.sendToKitchen(order!.id);
      order = await _orderRepository.getOpenOrderByTable(table.id);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  bool _isBeverageCategory(String category) {
    final normalized = category.toLowerCase();
    return normalized.contains('bebida') ||
        normalized.contains('drink') ||
        normalized.contains('refresco');
  }

  bool _isExtraCategory(String category) {
    final normalized = category.toLowerCase();
    return normalized.contains('extra') ||
        normalized.contains('complemento') ||
        normalized.contains('addon') ||
        normalized.contains('adicional');
  }
}
