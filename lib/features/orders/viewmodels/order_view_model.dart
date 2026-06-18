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

  static const String allCategory = 'Todos';
  static const String mainCategory = 'Platillos';
  static const String drinksCategory = 'Bebidas';
  static const String extrasCategory = 'Extras';

  static const List<String> preferredCategoryOrder = [
    allCategory,
    mainCategory,
    'Tostadas',
    'Tostitos',
    'Cócteles',
    'Especialidades',
    drinksCategory,
    extrasCategory,
  ];

  List<Product> products = [];
  Order? order;

  String selectedCategory = allCategory;

  bool showingCategories = true;
  bool isLoading = false;
  bool isSending = false;
  bool isOrderExpanded = false;

  String? errorMessage;

  List<String> get categories => const [
        allCategory,
        mainCategory,
        drinksCategory,
        extrasCategory,
      ];

  List<String> get realProductCategories {
    final uniqueCategories = <String>{
      for (final product in products)
        if (product.category.trim().isNotEmpty) product.category.trim(),
    }.toList();

    uniqueCategories.sort(_compareCategories);

    return uniqueCategories;
  }

  List<Product> get filteredProducts {
    switch (selectedCategory) {
      case mainCategory:
        return mainProducts;
      case drinksCategory:
        return beverageProducts;
      case extrasCategory:
        return extraProducts;
      case allCategory:
      default:
        return products;
    }
  }

  List<Product> get selectedCategoryProducts {
    return filteredProducts;
  }

  List<Product> get mainProducts {
    return products.where(isPrimaryProduct).toList();
  }

  List<Product> get beverageProducts {
    return products
        .where((product) => _isBeverageCategory(product.category))
        .toList();
  }

  List<Product> get extraProducts {
    return products
        .where((product) => _isExtraCategory(product.category))
        .toList();
  }

  bool isPrimaryProduct(Product product) {
    final category = product.category;

    return !_isBeverageCategory(category) && !_isExtraCategory(category);
  }

  Future<void> load(RestaurantTable table) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      products = _sortProducts(await _productRepository.getProducts());

      selectedCategory = allCategory;
      showingCategories = true;

      order = await _orderRepository.getOpenOrderByTable(table.id);

      if (order == null) {
        final userId = _authRepository.currentUser?.userId;

        if (userId == null) {
          throw Exception('No hay usuario autenticado.');
        }

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
    showingCategories = false;
    notifyListeners();
  }

  void backToCategories() {
    selectedCategory = allCategory;
    showingCategories = true;
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

      order = await _orderRepository.getOpenOrderByTable(table.id);
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
        if (complement.quantity <= 0) continue;

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
    final normalized = _normalize(category);

    return normalized.contains('bebida') ||
        normalized.contains('bebidas') ||
        normalized.contains('drink') ||
        normalized.contains('refresco') ||
        normalized.contains('agua') ||
        normalized.contains('soda');
  }

  bool _isExtraCategory(String category) {
    final normalized = _normalize(category);

    return normalized.contains('extra') ||
        normalized.contains('extras') ||
        normalized.contains('complemento') ||
        normalized.contains('complementos') ||
        normalized.contains('salsa') ||
        normalized.contains('salsas') ||
        normalized.contains('tortilla') ||
        normalized.contains('tortillas') ||
        normalized.contains('adicional');
  }

  List<Product> _sortProducts(List<Product> incomingProducts) {
    final sortedProducts = List<Product>.from(incomingProducts);

    sortedProducts.sort((left, right) {
      final categoryComparison = _compareCategories(
        left.category,
        right.category,
      );

      if (categoryComparison != 0) {
        return categoryComparison;
      }

      final leftSortOrder = left.sortOrder;
      final rightSortOrder = right.sortOrder;

      final leftHasSortOrder = leftSortOrder > 0;
      final rightHasSortOrder = rightSortOrder > 0;

      if (leftHasSortOrder && rightHasSortOrder) {
        final sortComparison = leftSortOrder.compareTo(rightSortOrder);

        if (sortComparison != 0) {
          return sortComparison;
        }
      } else if (leftHasSortOrder != rightHasSortOrder) {
        return leftHasSortOrder ? -1 : 1;
      }

      return left.name.toLowerCase().compareTo(right.name.toLowerCase());
    });

    return sortedProducts;
  }

  int _compareCategories(String left, String right) {
    final normalizedLeft = left.trim();
    final normalizedRight = right.trim();

    final leftIndex = preferredCategoryOrder.indexOf(normalizedLeft);
    final rightIndex = preferredCategoryOrder.indexOf(normalizedRight);

    if (leftIndex == -1 && rightIndex == -1) {
      return normalizedLeft.toLowerCase().compareTo(
            normalizedRight.toLowerCase(),
          );
    }

    if (leftIndex == -1) return 1;
    if (rightIndex == -1) return -1;

    return leftIndex.compareTo(rightIndex);
  }

  String _normalize(String value) {
    return value.toLowerCase().trim();
  }
}