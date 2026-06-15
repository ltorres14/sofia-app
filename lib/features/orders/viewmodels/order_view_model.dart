import 'package:flutter/material.dart';

import '../../../data/models/orders/order.dart';
import '../../../data/models/products/product.dart';
import '../../../data/models/tables/restaurant_table.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/table_repository.dart';

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
  String? errorMessage;

  List<String> get categories {
    final values = products.map((e) => e.category).toSet().toList()..sort();
    return ['Todos', ...values];
  }

  List<Product> get filteredProducts {
    if (selectedCategory == 'Todos') return products;
    return products.where((product) => product.category == selectedCategory).toList();
  }

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

  Future<void> addProduct(Product product, RestaurantTable table) async {
    if (order == null) return;
    isLoading = true;
    notifyListeners();
    try {
      await _orderRepository.addItem(orderId: order!.id, productId: product.id);
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
}
