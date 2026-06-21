import 'package:flutter/material.dart';

import '../../../data/models/orders/order.dart';
import '../../../data/models/products/product.dart';
import '../../../data/models/tables/restaurant_table.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/services/order_service.dart';
import '../models/product_selection.dart';

class OrderViewModel extends ChangeNotifier {
  OrderViewModel({
    required ProductRepository productRepository,
    required OrderRepository orderRepository,
    required TableRepository tableRepository,
    required AuthRepository authRepository,
  }) : _productRepository = productRepository,
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
    'CÃ³cteles',
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

  List<String> get foodCategories {
    return realProductCategories.where((category) {
      return !_matchesCategory(category, drinksCategory) &&
          !_matchesCategory(category, extrasCategory);
    }).toList();
  }

  List<String> get beverageCategories {
    return realProductCategories.where((category) {
      return _matchesCategory(category, drinksCategory);
    }).toList();
  }

  List<String> get extraCategories {
    return realProductCategories.where((category) {
      return _matchesCategory(category, extrasCategory);
    }).toList();
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
    return products.where((product) {
      return _productMatchesCategory(product, drinksCategory);
    }).toList();
  }

  List<Product> get extraProducts {
    return products.where((product) {
      return _productMatchesCategory(product, extrasCategory);
    }).toList();
  }

  List<Product> productsByCategory(String category) {
    if (_matchesCategory(category, drinksCategory)) {
      return beverageProducts;
    }

    if (_matchesCategory(category, extrasCategory)) {
      return extraProducts;
    }

    return products.where((product) {
      return _productMatchesCategory(product, category);
    }).toList();
  }

  bool isPrimaryProduct(Product product) {
    return !_productMatchesCategory(product, drinksCategory) &&
        !_productMatchesCategory(product, extrasCategory);
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
    showingCategories = category == mainCategory;
    notifyListeners();
  }

  void backToCategories() {
    selectedCategory = mainCategory;
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
      final selectionItems = <CreateOrderSelectionItemRequest>[
        CreateOrderSelectionItemRequest(
          productId: mainProduct.id,
          quantity: quantity,
          role: 1,
          sortOrder: 1,
          notes: '',
        ),
      ];

      var sortOrder = 2;

      for (final complement in complements) {
        if (complement.quantity <= 0) continue;

        selectionItems.add(
          CreateOrderSelectionItemRequest(
            productId: complement.product.id,
            quantity: complement.quantity,
            role: _resolveSelectionRole(complement),
            sortOrder: sortOrder,
            notes: '',
          ),
        );
        sortOrder++;
      }

      await _orderRepository.addSelection(
        orderId: order!.id,
        label: _buildNextSelectionLabel(),
        notes: '',
        items: selectionItems,
      );

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

  bool _productMatchesCategory(Product product, String category) {
    return _matchesCategory(product.category, category);
  }

  bool _matchesCategory(String category, String targetCategory) {
    return _normalize(category) == _normalize(targetCategory);
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
    return value
        .toLowerCase()
        .trim()
        .replaceAll('Ã¡', 'a')
        .replaceAll('Ã©', 'e')
        .replaceAll('Ã­', 'i')
        .replaceAll('Ã³', 'o')
        .replaceAll('Ãº', 'u')
        .replaceAll('Ã¼', 'u')
        .replaceAll('Ã±', 'n');
  }

  int _resolveSelectionRole(ProductSelection selection) {
    if (_productMatchesCategory(selection.product, drinksCategory)) {
      return 2;
    }

    if (_productMatchesCategory(selection.product, extrasCategory)) {
      return 3;
    }

    return 3;
  }

  String _buildNextSelectionLabel() {
    final nextSequence = (order?.selections.length ?? 0) + 1;
    return 'Seleccion $nextSequence';
  }
}
