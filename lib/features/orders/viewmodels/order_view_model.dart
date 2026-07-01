import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
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
    'Cocteles',
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
  String? actionErrorMessage;

  bool get isSendingToKitchen => isSending;

  List<String> get categories => const [
    allCategory,
    mainCategory,
    drinksCategory,
    extrasCategory,
  ];

  List<OrderSelection> get visibleSelections =>
      List<OrderSelection>.unmodifiable([
        ..._activeSelectionsFromOrder(order),
        ..._draftSelections.where(_isVisibleSelection),
      ]);

  List<OrderSelection> get localDraftSelections =>
      List<OrderSelection>.unmodifiable(
        _draftSelections.where(_isVisibleSelection),
      );

  bool get hasPendingItemsToSend {
    if (localDraftSelections.isNotEmpty) {
      return true;
    }

    return order?.items.any((item) => item.quantity > 0) ?? false;
  }

  double get visibleTotal {
    if (visibleSelections.isNotEmpty) {
      return visibleSelections.fold<double>(
        0,
        (sum, selection) => sum + selection.total,
      );
    }

    return order?.total ??
        order?.items.fold<double>(0, (sum, item) => sum + item.total) ??
        0;
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

  OrderSelection? selectionById(int selectionId) {
    for (final selection in visibleSelections) {
      if (selection.id == selectionId) {
        return selection;
      }
    }

    return null;
  }

  bool canEditSelection(OrderSelection selection) {
    return _isVisibleSelection(selection) && selection.resolvedCanEdit;
  }

  bool canDeleteSelection(OrderSelection selection) {
    return _isVisibleSelection(selection) && selection.resolvedCanDelete;
  }

  bool canEditSelectionComment(OrderSelection selection) {
    return _isVisibleSelection(selection) &&
        !selection.isCancelled &&
        selection.id != 0;
  }

  String statusLabelForSelection(OrderSelection selection) {
    return selection.statusLabel;
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

  Future<void> load(RestaurantTable table, {bool showLoading = true}) async {
    _currentTableId = table.id;

    if (showLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      if (products.isEmpty) {
        products = _sortProducts(await _productRepository.getProducts());
      }

      if (showLoading) {
        selectedCategory = allCategory;
        showingCategories = true;
      }

      await _loadOrCreateOrder(table.id);
      _restoreDraftSelectionsForTable(table.id);

      if (showLoading) {
        errorMessage = null;
      }
    } catch (error) {
      if (showLoading) {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (showLoading) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> refreshCurrentTableOrder({bool showLoading = false}) async {
    final currentTableId = _currentTableId;
    if (currentTableId == null) {
      return;
    }

    if (showLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      order = await _orderRepository.getOpenOrderByTable(currentTableId);
      if (showLoading) {
        errorMessage = null;
      }
    } catch (error) {
      if (showLoading) {
        errorMessage = error.toString().replaceFirst('Exception: ', '');
      }
    } finally {
      if (showLoading) {
        isLoading = false;
      }
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

      await refreshCurrentTableOrder();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
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
    _currentTableId = table.id;
    errorMessage = null;

    try {
      _draftSelections = [
        ...localDraftSelections,
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
      notifyListeners();
    }
  }

  Future<void> saveSelectionChanges({
    required OrderSelection selection,
    required Product mainProduct,
    required int quantity,
    required List<ProductSelection> complements,
  }) async {
    if (selection.isLocalDraft) {
      replaceSelectionLocally(
        selection: selection,
        mainProduct: mainProduct,
        quantity: quantity,
        complements: complements,
      );
      return;
    }

    actionErrorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      await _orderRepository.updateSelection(
        selectionId: selection.id,
        label: selection.label,
        notes: selection.displayComment,
        items: _buildRequestItems(
          mainProduct: mainProduct,
          quantity: quantity,
          complements: complements,
        ),
      );
      await refreshCurrentTableOrder();
    } catch (error) {
      await _handleActionError(error, refreshAfterConflict: true);
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
    final currentSelections = localDraftSelections;
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
        comment: currentSelection.comment,
        notes: currentSelection.notes,
        createdAt: currentSelection.createdAt,
        status: currentSelection.status,
      );
    }).toList();

    _saveCurrentDraft();
    notifyListeners();
  }

  Future<void> deleteSelection(OrderSelection selection) async {
    if (selection.isLocalDraft) {
      removeSelectionLocally(selection.id);
      return;
    }

    actionErrorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      await _orderRepository.deleteSelection(selection.id);
      await refreshCurrentTableOrder();
    } catch (error) {
      await _handleActionError(error, refreshAfterConflict: true);
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSelectionComment({
    required OrderSelection selection,
    required String comment,
  }) async {
    if (selection.isLocalDraft) {
      _updateLocalSelectionComment(selection.id, comment);
      return true;
    }

    final currentOrder = order;
    if (currentOrder == null ||
        currentOrder.id <= 0 ||
        selection.id <= 0 ||
        selection.isCancelled) {
      return false;
    }

    actionErrorMessage = null;
    isLoading = true;
    notifyListeners();

    try {
      await _orderRepository.updateSelectionComment(
        orderId: currentOrder.id,
        selectionId: selection.id,
        comment: comment,
      );
      await refreshCurrentTableOrder();
      return true;
    } catch (error) {
      await _handleActionError(error, refreshAfterConflict: true);
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void _updateLocalSelectionComment(int selectionId, String comment) {
    _draftSelections = localDraftSelections.map((selection) {
      if (selection.id != selectionId) {
        return selection;
      }

      return selection.copyWith(comment: comment, notes: comment);
    }).toList();

    _saveCurrentDraft();
    notifyListeners();
  }

  void removeSelectionLocally(int selectionId) {
    final remainingSelections = localDraftSelections
        .where((selection) => selection.id != selectionId)
        .toList();

    _draftSelections = [
      for (var index = 0; index < remainingSelections.length; index++)
        _copySelectionWithSequence(
          remainingSelections[index],
          sequenceNumber: _activeSelectionsFromOrder(order).length + index + 1,
        ),
    ];

    _saveCurrentDraft();
    notifyListeners();
  }

  Future<bool> sendToKitchen() async {
    final currentOrder = order;
    final draftSelectionsToSend = localDraftSelections
        .where((selection) => selection.items.any((item) => item.quantity > 0))
        .toList();
    final hasLegacyItems =
        currentOrder?.items.any((item) => item.quantity > 0) ?? false;

    if (currentOrder == null || currentOrder.id <= 0 || isSending) {
      return false;
    }

    if (draftSelectionsToSend.isEmpty && !hasLegacyItems) {
      actionErrorMessage = 'No hay productos para enviar a cocina.';
      notifyListeners();
      return false;
    }

    isSending = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      if (draftSelectionsToSend.isNotEmpty) {
        await _persistDraftSelectionsForSend(draftSelectionsToSend);
      }

      await _orderRepository.sendToKitchen(currentOrder.id);
      _clearCurrentDrafts();
      await refreshCurrentTableOrder();
      return true;
    } catch (error) {
      await _handleActionError(error);
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }

  void clearActionError() {
    if (actionErrorMessage == null) {
      return;
    }

    actionErrorMessage = null;
    notifyListeners();
  }

  OrderSelection _buildLocalSelection({
    required Product mainProduct,
    required int quantity,
    required List<ProductSelection> complements,
    required int sequenceNumber,
    int? selectionId,
    String? label,
    String? comment,
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
      comment: comment,
      notes: notes,
      status: status ?? OrderSelection.draftStatus,
      canEdit: true,
      canDelete: true,
      createdAt: createdAt ?? DateTime.now(),
      total: items.fold<double>(0, (sum, item) => sum + item.total),
      items: items,
    );
  }

  List<CreateOrderSelectionItemRequest> _buildRequestItems({
    required Product mainProduct,
    required int quantity,
    required List<ProductSelection> complements,
  }) {
    final items = <CreateOrderSelectionItemRequest>[
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

      items.add(
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

    return items;
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

  Future<void> _loadOrCreateOrder(int tableId) async {
    order = await _orderRepository.getOpenOrderByTable(tableId);

    if (order != null) {
      return;
    }

    final userId = _authRepository.currentUser?.userId;
    if (userId == null) {
      throw Exception('No hay usuario autenticado.');
    }

    await _tableRepository.openTable(tableId, userId);
    order = await _orderRepository.getOpenOrderByTable(tableId);
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
        notes: selection.displayComment,
        items: items,
      );
    }

    order = latestOrder;
  }

  bool _isVisibleSelection(OrderSelection selection) {
    return !selection.isCancelled && selection.hasVisibleItems;
  }

  List<OrderSelection> _activeSelectionsFromOrder(Order? sourceOrder) {
    return (sourceOrder?.selections ?? const <OrderSelection>[])
        .where(_isVisibleSelection)
        .toList();
  }

  void _restoreDraftSelectionsForTable(int tableId) {
    final savedDraftSelections = _draftSelectionsByTable[tableId];
    _draftSelections = List<OrderSelection>.from(
      savedDraftSelections ?? const [],
    );
  }

  void _saveCurrentDraft() {
    if (_currentTableId == null) {
      return;
    }

    final visibleDrafts = _draftSelections.where(_isVisibleSelection).toList();
    _draftSelections = visibleDrafts;

    if (visibleDrafts.isEmpty) {
      _draftSelectionsByTable.remove(_currentTableId!);
      return;
    }

    _draftSelectionsByTable[_currentTableId!] = List<OrderSelection>.from(
      visibleDrafts,
    );
  }

  void _clearCurrentDrafts() {
    if (_currentTableId != null) {
      _draftSelectionsByTable.remove(_currentTableId!);
    }
    _draftSelections = [];
  }

  Future<void> _handleActionError(
    Object error, {
    bool refreshAfterConflict = false,
  }) async {
    final message = error.toString().replaceFirst('Exception: ', '');

    if (error is ApiException && error.statusCode == 409) {
      actionErrorMessage = message.isNotEmpty
          ? message
          : 'La seleccion ya comenzo a prepararse y no puede modificarse.';
      if (refreshAfterConflict && _currentTableId != null) {
        try {
          order = await _orderRepository.getOpenOrderByTable(_currentTableId!);
        } catch (_) {}
      }
      return;
    }

    actionErrorMessage = message;
  }

  int _buildLocalSelectionId(int sequenceNumber) => -sequenceNumber;

  int _buildLocalItemId(int sequenceNumber, int sortOrder) {
    return -((sequenceNumber * 100) + sortOrder);
  }

  OrderSelection _copySelectionWithSequence(
    OrderSelection selection, {
    required int sequenceNumber,
  }) {
    return selection.copyWith(
      sequenceNumber: sequenceNumber,
      label: 'Seleccion $sequenceNumber',
    );
  }

  static int draftSelectionCountForTable(int tableId) {
    return _draftSelectionsByTable[tableId]
            ?.where((selection) => selection.hasVisibleItems)
            .length ??
        0;
  }
}
