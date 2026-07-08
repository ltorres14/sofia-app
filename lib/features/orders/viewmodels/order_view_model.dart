import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/activity/recent_activity_item.dart';
import '../../../data/models/kitchen/kitchen_ticket.dart';
import '../../../data/models/orders/order.dart';
import '../../../data/models/orders/order_selection.dart';
import '../../../data/models/orders/order_selection_item.dart';
import '../../../data/models/products/product.dart';
import '../../../data/models/tables/restaurant_table.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/product_repository.dart';
import '../../../data/repositories/table_repository.dart';
import '../../../data/services/kitchen_realtime_service.dart';
import '../../../data/services/order_service.dart';
import '../models/product_selection.dart';

class OrderViewModel extends ChangeNotifier {
  OrderViewModel({
    required ProductRepository productRepository,
    required OrderRepository orderRepository,
    required TableRepository tableRepository,
    required AuthRepository authRepository,
    required KitchenRealtimeService kitchenRealtimeService,
  }) : _productRepository = productRepository,
       _orderRepository = orderRepository,
       _tableRepository = tableRepository,
       _authRepository = authRepository,
       _kitchenRealtimeService = kitchenRealtimeService;

  final ProductRepository _productRepository;
  final OrderRepository _orderRepository;
  final TableRepository _tableRepository;
  final AuthRepository _authRepository;
  final KitchenRealtimeService _kitchenRealtimeService;

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
  List<RecentActivityItem> recentActivities = [];
  Order? order;
  List<OrderSelection> _draftSelections = [];
  int? _currentTableId;

  String selectedCategory = allCategory;

  bool showingCategories = true;
  bool isLoading = false;
  bool isSending = false;
  bool isRequestingPayment = false;
  bool isOrderExpanded = false;
  bool isRecentActivityLoading = false;

  String? errorMessage;
  String? actionErrorMessage;
  String? recentActivityErrorMessage;
  StreamSubscription<KitchenTicket>? _ticketSubscription;
  bool _realtimeStarted = false;

  void _debugLog(String message) {
    assert(() {
      debugPrint('[OrderViewModel] $message');
      return true;
    }());
  }

  bool get isSendingToKitchen => isSending;
  bool get isWaitingPayment => order?.isWaitingPayment ?? false;
  bool get canModifyOrder => !isWaitingPayment;
  bool get hasOrderSelectionsSentToKitchen =>
      _sentSelectionsForBilling.isNotEmpty;
  bool get hasPendingSelectionsToSend {
    if (!canModifyOrder) {
      return false;
    }

    return currentSelections.any(
          (selection) => selection.isLocalDraft || selection.isDraft,
        ) ||
        (order?.items.any((item) => item.quantity > 0 && !item.sentToKitchen) ??
            false);
  }

  bool get hasPendingKitchenSelections {
    return _sentSelectionsForBilling.any((selection) => !selection.isReady);
  }

  String? get requestBillBlockedMessage {
    final currentOrder = order;
    if (currentOrder == null || currentOrder.id <= 0) {
      return 'No hay una orden activa.';
    }

    if (currentOrder.isWaitingPayment) {
      return 'La mesa ya esta esperando cobro.';
    }

    if (!currentOrder.isOpen) {
      return 'No hay una orden activa.';
    }

    if (hasPendingSelectionsToSend) {
      return 'Envia primero los platillos a cocina.';
    }

    if (!hasOrderSelectionsSentToKitchen) {
      return 'Envia primero los platillos a cocina.';
    }

    if (hasPendingKitchenSelections) {
      return 'Aun hay platillos pendientes en cocina.';
    }

    return null;
  }

  List<String> get categories => const [
    allCategory,
    mainCategory,
    drinksCategory,
    extrasCategory,
  ];

  List<OrderSelection> get currentSelections =>
      List<OrderSelection>.unmodifiable([
        ..._activeSelectionsFromOrder(order),
        ..._draftSelections.where(_isVisibleSelection),
      ]);

  List<OrderSelection> get visibleSelections => currentSelections;

  List<OrderSelection> get localDraftSelections =>
      List<OrderSelection>.unmodifiable(
        _draftSelections.where(_isVisibleSelection),
      );

  bool get hasPendingItemsToSend {
    if (!canModifyOrder) {
      return false;
    }

    final result =
        currentSelections.any(_isSendableSelection) ||
        (order?.items.any((item) => item.quantity > 0 && !item.sentToKitchen) ??
            false);
    _debugLog(
      'hasPendingItemsToSend=$result, '
      'currentSelections=${currentSelections.length}, '
      'isSending=$isSending',
    );
    if (result) {
      return true;
    }
    return false;
  }

  bool get canSendToPayment {
    return requestBillBlockedMessage == null;
  }

  double get visibleTotal {
    if (currentSelections.isNotEmpty) {
      return currentSelections.fold<double>(
        0,
        (sum, selection) => sum + selection.total,
      );
    }

    return order?.total ??
        order?.items.fold<double>(0, (sum, item) => sum + item.total) ??
        0;
  }

  int get visibleItemCount {
    if (currentSelections.isNotEmpty) {
      return currentSelections.length;
    }

    return order?.items.fold<int>(0, (sum, item) => sum + item.quantity) ?? 0;
  }

  OrderSelection? selectionById(int selectionId) {
    for (final selection in currentSelections) {
      if (selection.id == selectionId) {
        return selection;
      }
    }

    return null;
  }

  bool canEditSelection(OrderSelection selection) {
    return canModifyOrder &&
        _isVisibleSelection(selection) &&
        selection.resolvedCanEdit;
  }

  bool canDeleteSelection(OrderSelection selection) {
    return canModifyOrder &&
        _isVisibleSelection(selection) &&
        selection.resolvedCanDelete;
  }

  bool canEditSelectionComment(OrderSelection selection) {
    return canModifyOrder &&
        _isVisibleSelection(selection) &&
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
      _syncDraftAvailabilityWithOrder();
      await _loadRecentActivity(
        showLoadingState: showLoading && recentActivities.isEmpty,
        notify: false,
      );

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
      _syncDraftAvailabilityWithOrder();
      await _loadRecentActivity(showLoadingState: false, notify: false);
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

  Future<void> startRealtime() async {
    if (_realtimeStarted) {
      return;
    }

    _ticketSubscription = _kitchenRealtimeService.tickets.listen(
      _handleIncomingKitchenTicket,
    );
    _realtimeStarted = true;

    try {
      await _kitchenRealtimeService.start();
    } catch (_) {}
  }

  Future<void> stopRealtime() async {
    await _ticketSubscription?.cancel();
    _ticketSubscription = null;
    _realtimeStarted = false;

    try {
      await _kitchenRealtimeService.stop();
    } catch (_) {}
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
    if (order == null || !canModifyOrder) return;

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
    String comment = '',
  }) async {
    if (!canModifyOrder) {
      return;
    }

    _currentTableId = table.id;
    errorMessage = null;

    try {
      _draftSelections = [
        ...localDraftSelections,
        _buildLocalSelection(
          mainProduct: mainProduct,
          quantity: quantity,
          complements: complements,
          comment: comment.trim(),
          sequenceNumber: currentSelections.length + 1,
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
    String comment = '',
  }) async {
    if (!canModifyOrder) {
      return;
    }

    if (selection.isLocalDraft) {
      replaceSelectionLocally(
        selection: selection,
        mainProduct: mainProduct,
        quantity: quantity,
        complements: complements,
        comment: comment.trim(),
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
        notes: comment.trim(),
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
    String comment = '',
  }) {
    if (!canModifyOrder) {
      return;
    }

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
        comment: comment.trim(),
        notes: comment.trim(),
        createdAt: currentSelection.createdAt,
        status: currentSelection.status,
      );
    }).toList();

    _saveCurrentDraft();
    notifyListeners();
  }

  Future<void> deleteSelection(OrderSelection selection) async {
    if (!canModifyOrder) {
      return;
    }

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
    if (!canModifyOrder) {
      return false;
    }

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
    if (!canModifyOrder) {
      return;
    }

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
    if (!canModifyOrder) {
      return;
    }

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
    if (!canModifyOrder) {
      return false;
    }

    final currentOrder = order;
    final sendableSelections = currentSelections
        .where(_isSendableSelection)
        .toList();
    final draftSelectionsToSend = sendableSelections
        .where((selection) => selection.isLocalDraft)
        .toList();
    final hasRemoteDraftSelections = sendableSelections.any(
      (selection) => !selection.isLocalDraft,
    );
    final hasLegacyItems =
        currentOrder?.items.any((item) => item.quantity > 0) ?? false;

    _debugLog(
      'sendToKitchen start: '
      'currentSelections=${currentSelections.length}, '
      'sendableSelections=${sendableSelections.length}, '
      'localDrafts=${draftSelectionsToSend.length}, '
      'remoteDrafts=$hasRemoteDraftSelections, '
      'legacyItems=$hasLegacyItems, '
      'isSending=$isSending',
    );

    if (isSending) {
      _debugLog(
        'sendToKitchen abortado: '
        'orderId=${order?.id}, isSending=$isSending',
      );
      return false;
    }

    if (draftSelectionsToSend.isEmpty &&
        !hasRemoteDraftSelections &&
        !hasLegacyItems) {
      actionErrorMessage = 'No hay productos para enviar a cocina.';
      _debugLog('sendToKitchen abortado: no hay productos enviables.');
      notifyListeners();
      return false;
    }

    isSending = true;
    actionErrorMessage = null;
    _debugLog('sendToKitchen marcado como en progreso.');
    notifyListeners();

    try {
      if ((order == null || order!.id <= 0) &&
          draftSelectionsToSend.isNotEmpty) {
        await _ensurePersistedOrderForCurrentTable();
      }

      final currentOrder = order;
      if (currentOrder == null || currentOrder.id <= 0) {
        throw Exception(
          'No se pudo crear o recuperar la orden antes de enviar a cocina.',
        );
      }

      if (draftSelectionsToSend.isNotEmpty) {
        await _persistDraftSelectionsForSend(draftSelectionsToSend);
      }

      await _orderRepository.sendToKitchen(currentOrder.id);
      _clearCurrentDrafts();
      await refreshCurrentTableOrder();
      _debugLog('sendToKitchen completado con exito.');
      return true;
    } catch (error) {
      _debugLog('sendToKitchen fallo: $error');
      await _handleActionError(error);
      return false;
    } finally {
      isSending = false;
      _debugLog('sendToKitchen finalizado. isSending=false.');
      notifyListeners();
    }
  }

  Future<bool> requestBill() async {
    if (isRequestingPayment) {
      return false;
    }

    final blockedMessage = requestBillBlockedMessage;
    if (blockedMessage != null) {
      actionErrorMessage = blockedMessage;
      notifyListeners();
      return false;
    }

    final currentOrder = order;
    if (currentOrder == null) {
      return false;
    }

    isRequestingPayment = true;
    actionErrorMessage = null;
    notifyListeners();

    try {
      await _orderRepository.requestBill(currentOrder.id);
      _clearCurrentDrafts();
      await refreshCurrentTableOrder();
      return true;
    } catch (error) {
      await _handleActionError(error, refreshAfterConflict: true);
      return false;
    } finally {
      isRequestingPayment = false;
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

    final normalizedComment = comment?.trim() ?? '';
    final resolvedLabel = (label != null && label.trim().isNotEmpty)
        ? label
        : mainProduct.name;

    return OrderSelection(
      id: selectionId ?? _buildLocalSelectionId(sequenceNumber),
      sequenceNumber: sequenceNumber,
      label: resolvedLabel,
      comment: normalizedComment,
      notes: normalizedComment.isNotEmpty ? normalizedComment : notes,
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

  Future<void> _loadRecentActivity({
    bool showLoadingState = false,
    bool notify = true,
  }) async {
    if (showLoadingState) {
      isRecentActivityLoading = true;
      recentActivityErrorMessage = null;
      if (notify) {
        notifyListeners();
      }
    }

    try {
      recentActivities = await _orderRepository.getRecentActivity(limit: 20);
      recentActivityErrorMessage = null;
    } catch (error) {
      recentActivityErrorMessage = error.toString().replaceFirst(
        'Exception: ',
        '',
      );
    } finally {
      if (showLoadingState) {
        isRecentActivityLoading = false;
      }
      if (notify) {
        notifyListeners();
      }
    }
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

    try {
      await _tableRepository.openTable(tableId, userId);
    } on ApiException catch (error) {
      if (error.statusCode == 500) {
        final recoveredOrder = await _orderRepository.getOpenOrderByTable(
          tableId,
        );
        if (recoveredOrder != null) {
          order = recoveredOrder;
          return;
        }
      }
      rethrow;
    }

    order = await _orderRepository.getOpenOrderByTable(tableId);
  }

  Future<void> _ensurePersistedOrderForCurrentTable() async {
    final tableId = _currentTableId;
    if (tableId == null) {
      throw Exception('No se encontro la mesa actual.');
    }

    _debugLog('Asegurando orden persistida para mesa $tableId.');
    await _loadOrCreateOrder(tableId);

    if (order == null || order!.id <= 0) {
      throw Exception('No se pudo crear o recuperar la orden de la mesa.');
    }

    _debugLog('Orden persistida disponible con orderId=${order!.id}.');
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

  bool _isSendableSelection(OrderSelection selection) {
    return _isVisibleSelection(selection) &&
        selection.isDraft &&
        selection.items.any((item) => item.quantity > 0);
  }

  List<OrderSelection> _activeSelectionsFromOrder(Order? sourceOrder) {
    return (sourceOrder?.selections ?? const <OrderSelection>[])
        .where(_isVisibleSelection)
        .toList();
  }

  List<OrderSelection> get _sentSelectionsForBilling {
    return currentSelections.where((selection) {
      return _isVisibleSelection(selection) &&
          !selection.isLocalDraft &&
          !selection.isDraft &&
          !selection.isCancelled &&
          selection.items.any((item) => item.quantity > 0);
    }).toList();
  }

  void _restoreDraftSelectionsForTable(int tableId) {
    final savedDraftSelections = _draftSelectionsByTable[tableId];
    _draftSelections = List<OrderSelection>.from(
      savedDraftSelections ?? const [],
    );
  }

  void _syncDraftAvailabilityWithOrder() {
    if (order?.isOpen ?? true) {
      return;
    }

    _clearCurrentDrafts();
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
          _syncDraftAvailabilityWithOrder();
        } catch (_) {}
      }
      return;
    }

    actionErrorMessage = message;
  }

  void _handleIncomingKitchenTicket(KitchenTicket ticket) {
    final currentOrderId = order?.id;
    if (currentOrderId == null || currentOrderId <= 0) {
      return;
    }

    if (ticket.orderId != currentOrderId) {
      return;
    }

    unawaited(refreshCurrentTableOrder());
  }

  int _buildLocalSelectionId(int sequenceNumber) => -sequenceNumber;

  int _buildLocalItemId(int sequenceNumber, int sortOrder) {
    return -((sequenceNumber * 100) + sortOrder);
  }

  OrderSelection _copySelectionWithSequence(
    OrderSelection selection, {
    required int sequenceNumber,
  }) {
    return selection.copyWith(sequenceNumber: sequenceNumber);
  }

  static int draftSelectionCountForTable(int tableId) {
    return _draftSelectionsByTable[tableId]
            ?.where((selection) => selection.hasVisibleItems)
            .length ??
        0;
  }

  @override
  void dispose() {
    unawaited(stopRealtime());
    super.dispose();
  }
}
