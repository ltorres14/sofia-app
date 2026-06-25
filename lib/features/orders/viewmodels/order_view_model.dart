import 'package:flutter/material.dart';

import '../../../data/models/orders/order.dart';
import '../../../data/models/orders/order_selection.dart';
import '../../../data/models/orders/order_selection_item.dart';
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
    'Cócteles',
    'Especialidades',
    drinksCategory,
    extrasCategory,
  ];

  static final Map<int, List<OrderSelection>> _draftSelectionsByTable = {};

  List<Product> products = [];
  Order? order;
  List<OrderSelection> _draftSelections = [];
  int? _currentTableId;

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

  List<OrderSelection> get visibleSelections {
    if (_draftSelections.isNotEmpty) {
      return List<OrderSelection>.unmodifiable(_draftSelections);
    }

    return List<OrderSelection>.unmodifiable(order?.selections ?? const []);
  }

  double get visibleTotal {
    if (visibleSelections.isNotEmpty) {
      return visibleSelections.fold<double>(
        0,
        (sum, selection) => sum + selection.total,
      );
    }

    return order?.items.fold<double>(0, (sum, item) => sum + item.total) ?? 0;
  }

  int get visibleItemCount {
    if (visibleSelections.isNotEmpty) {
      return visibleSelections.fold<int>(
        0,
        (sum, selection) =>
            sum +
            selection.items.fold<int>(
              0,
              (itemSum, item) => itemSum + item.quantity,
            ),
      );
    }

    return order?.items.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
  }

  bool get hasPendingLocalSelectionChanges {
    final persistedSelections = order?.selections ?? const <OrderSelection>[];

    if (_draftSelections.length != persistedSelections.length) {
      return _draftSelections.isNotEmpty || persistedSelections.isNotEmpty;
    }

    for (var index = 0; index < _draftSelections.length; index++) {
      final draft = _draftSelections[index];
      final persisted = persistedSelections[index];

      if (draft.id != persisted.id ||
          draft.sequenceNumber != persisted.sequenceNumber ||
          draft.label != persisted.label ||
          draft.notes != persisted.notes ||
          draft.total != persisted.total ||
          draft.items.length != persisted.items.length) {
        return true;
      }

      for (var itemIndex = 0; itemIndex < draft.items.length; itemIndex++) {
        final draftItem = draft.items[itemIndex];
        final persistedItem = persisted.items[itemIndex];

        if (draftItem.productId != persistedItem.productId ||
            draftItem.quantity != persistedItem.quantity ||
            draftItem.unitPrice != persistedItem.unitPrice ||
            draftItem.total != persistedItem.total ||
            draftItem.role != persistedItem.role ||
            draftItem.sortOrder != persistedItem.sortOrder ||
            draftItem.notes != persistedItem.notes) {
          return true;
        }
      }
    }

    return false;
  }

  OrderSelection? selectionById(int selectionId) {
    for (final selection in visibleSelections) {
      if (selection.id == selectionId) {
        return selection;
      }
    }

    return null;
  }

  Product? productById(int productId) {
    for (final product in products) {
      if (product.id == productId) {
        return product;
      }
    }

    return null;
  }

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
    _currentTableId = table.id;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      products = _sortProducts(await _productRepository.getProducts());

      selectedCategory = allCategory;
      showingCategories = true;

      order = await _orderRepository.getOpenOrderByTable(table.id);
      _restoreDraftSelectionsForTable(table.id);

      if (order == null) {
        final userId = _authRepository.currentUser?.userId;

        if (userId == null) {
          throw Exception('No hay usuario autenticado.');
        }

        await _tableRepository.openTable(table.id, userId);
        order = await _orderRepository.getOpenOrderByTable(table.id);
        _restoreDraftSelectionsForTable(table.id);
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
      _restoreDraftSelectionsForTable(table.id);
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

    _currentTableId = table.id;
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      _draftSelections = [
        ...visibleSelections,
        _buildLocalSelection(
          mainProduct: mainProduct,
          quantity: quantity,
          complements: complements,
          sequenceNumber: visibleSelections.length + 1,
        ),
      ];

      _saveCurrentDraft();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void replaceSelectionLocally({
    required OrderSelection selection,
    required Product mainProduct,
    required int quantity,
    required List<ProductSelection> complements,
  }) {
    final currentSelections = visibleSelections;
    if (currentSelections.isEmpty) return;

    _draftSelections = currentSelections.map((currentSelection) {
      if (currentSelection.id != selection.id) {
        return currentSelection;
      }

      return _buildLocalSelection(
        mainProduct: mainProduct,
        quantity: quantity,
        complements: complements,
        sequenceNumber: currentSelection.sequenceNumber,
        selectionId: currentSelection.id,
        label: currentSelection.label,
        notes: currentSelection.notes,
        createdAt: currentSelection.createdAt,
        status: currentSelection.status,
      );
    }).toList();

    _saveCurrentDraft();
    notifyListeners();
  }

  void removeSelectionLocally(int selectionId) {
    final currentSelections = visibleSelections;
    if (currentSelections.isEmpty) return;

    final remainingSelections = currentSelections
        .where((selection) => selection.id != selectionId)
        .toList();

    _draftSelections = [
      for (var index = 0; index < remainingSelections.length; index++)
        _copySelectionWithSequence(
          remainingSelections[index],
          sequenceNumber: index + 1,
        ),
    ];

    _saveCurrentDraft();
    notifyListeners();
  }

  Future<bool> sendToKitchen() async {
    final hasPendingChanges = hasPendingLocalSelectionChanges;
    final currentOrder = order;
    final validSelections = visibleSelections
        .where((selection) => selection.items.any((item) => item.quantity > 0))
        .toList();
    if (currentOrder == null) return false;
    if (currentOrder.id <= 0) return false;
    if (isSending) return false;
    if (validSelections.isEmpty && currentOrder.items.isEmpty) {
      errorMessage = 'No hay productos para enviar a cocina';
      notifyListeners();
      return false;
    }

    isSending = true;
    errorMessage = null;
    notifyListeners();

    try {
      if (hasPendingChanges && validSelections.isNotEmpty) {
        await _persistDraftSelectionsForSend(validSelections);
      }

      await _orderRepository.sendToKitchen(order!.id);
      return true;
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  Future<void> _persistDraftSelectionsForSend(
    List<OrderSelection> selections,
  ) async {
    var latestOrder = order;

    for (final selection in selections) {
      final items = selection.items
          .where((item) => item.quantity > 0)
          .map(
            (item) => CreateOrderSelectionItemRequest(
              productId: item.productId,
              quantity: item.quantity,
              role: item.role,
              sortOrder: item.sortOrder,
              notes: item.notes,
            ),
          )
          .toList();

      if (items.isEmpty) {
        continue;
      }

      latestOrder = await _orderRepository.addSelection(
        orderId: latestOrder!.id,
        label: selection.label,
        notes: selection.notes,
        items: items,
      );
    }

    order = latestOrder;
    _syncDraftSelectionsFromOrder();
  }

  Future<void> refreshAfterSendToKitchen(RestaurantTable table) async {
    try {
      order = await _orderRepository.getOpenOrderByTable(table.id);
      _syncDraftSelectionsFromOrder();
      _draftSelectionsByTable.remove(table.id);
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      notifyListeners();
    }
  }

  OrderSelection _buildLocalSelection({
    required Product mainProduct,
    required int quantity,
    required List<ProductSelection> complements,
    required int sequenceNumber,
    int? selectionId,
    String? label,
    String? notes,
    DateTime? createdAt,
    int? status,
  }) {
    final items = <OrderSelectionItem>[
      OrderSelectionItem(
        id: _buildLocalItemId(sequenceNumber, 1),
        productId: mainProduct.id,
        productName: mainProduct.name,
        quantity: quantity,
        unitPrice: mainProduct.price,
        total: mainProduct.price * quantity,
        role: 1,
        sortOrder: 1,
        notes: '',
      ),
    ];

    var sortOrder = 2;

    for (final complement in complements) {
      if (complement.quantity <= 0) continue;

      items.add(
        OrderSelectionItem(
          id: _buildLocalItemId(sequenceNumber, sortOrder),
          productId: complement.product.id,
          productName: complement.product.name,
          quantity: complement.quantity,
          unitPrice: complement.product.price,
          total: complement.product.price * complement.quantity,
          role: _resolveSelectionRole(complement),
          sortOrder: sortOrder,
          notes: '',
        ),
      );
      sortOrder++;
    }

    final resolvedLabel = (label != null && label.trim().isNotEmpty)
        ? label
        : 'Seleccion $sequenceNumber';

    return OrderSelection(
      id: selectionId ?? _buildLocalSelectionId(sequenceNumber),
      sequenceNumber: sequenceNumber,
      label: resolvedLabel,
      notes: notes,
      status: status ?? 1,
      createdAt: createdAt ?? DateTime.now(),
      total: items.fold<double>(0, (sum, item) => sum + item.total),
      items: items,
    );
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
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n');
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

  void _syncDraftSelectionsFromOrder() {
    _draftSelections = List<OrderSelection>.from(order?.selections ?? const []);
  }

  void _restoreDraftSelectionsForTable(int tableId) {
    final savedDraftSelections = _draftSelectionsByTable[tableId];

    if (savedDraftSelections != null) {
      _draftSelections = List<OrderSelection>.from(savedDraftSelections);
      return;
    }

    _syncDraftSelectionsFromOrder();
  }

  void _saveCurrentDraft() {
    if (_currentTableId == null) return;

    _draftSelectionsByTable[_currentTableId!] = List<OrderSelection>.from(
      _draftSelections,
    );
  }

  int _buildLocalSelectionId(int sequenceNumber) => -sequenceNumber;

  int _buildLocalItemId(int sequenceNumber, int sortOrder) {
    return -((sequenceNumber * 100) + sortOrder);
  }

  OrderSelection _copySelectionWithSequence(
    OrderSelection selection, {
    required int sequenceNumber,
  }) {
    return OrderSelection(
      id: selection.id,
      sequenceNumber: sequenceNumber,
      label: 'Selección $sequenceNumber',
      notes: selection.notes,
      status: selection.status,
      createdAt: selection.createdAt,
      total: selection.total,
      items: selection.items,
    );
  }

  static int? draftSelectionCountForTable(int tableId) {
    return _draftSelectionsByTable[tableId]?.length;
  }
}

