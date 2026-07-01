import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/orders/order.dart';
import '../../../data/models/tables/restaurant_table.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/order_repository.dart';
import '../../../data/repositories/table_repository.dart';

class TablesViewModel extends ChangeNotifier {
  TablesViewModel({
    required TableRepository tableRepository,
    required OrderRepository orderRepository,
    required AuthRepository authRepository,
  }) : _tableRepository = tableRepository,
       _orderRepository = orderRepository,
       _authRepository = authRepository;

  final TableRepository _tableRepository;
  final OrderRepository _orderRepository;
  final AuthRepository _authRepository;

  List<RestaurantTable> tables = [];
  final Map<int, int> _openOrderSelectionCountByTable = {};
  bool isLoading = false;
  String? errorMessage;
  String? actionErrorMessage;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      tables = await _tableRepository.getTables();
      await _refreshOpenOrderSelectionCounts(tables);
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

  Future<void> ensureOrderForTable(RestaurantTable table) async {
    actionErrorMessage = null;
    notifyListeners();

    try {
      final existing = await _orderRepository.getOpenOrderByTable(table.id);
      if (existing != null) return;

      final userId = _authRepository.currentUser?.userId;
      if (userId == null) {
        throw Exception('No hay usuario activo.');
      }

      try {
        await _tableRepository.openTable(table.id, userId);
      } on ApiException catch (error) {
        if (error.statusCode == 500) {
          final recoveredOrder = await _orderRepository.getOpenOrderByTable(
            table.id,
          );
          if (recoveredOrder != null) {
            _openOrderSelectionCountByTable[table.id] = _selectionCountForOrder(
              recoveredOrder,
            );
            return;
          }
        }
        rethrow;
      }
    } catch (error) {
      actionErrorMessage = error.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  int displayedSelectionCountForTable(
    RestaurantTable table, {
    int? draftSelectionCount,
  }) {
    final backendCount =
        _openOrderSelectionCountByTable[table.id] ?? table.activeOrdersCount;
    final localDraftCount = draftSelectionCount ?? 0;
    return backendCount + localDraftCount;
  }

  void clearActionError() {
    if (actionErrorMessage == null) return;
    actionErrorMessage = null;
    notifyListeners();
  }

  Future<void> _refreshOpenOrderSelectionCounts(
    List<RestaurantTable> loadedTables,
  ) async {
    final nextCounts = <int, int>{};

    await Future.wait(
      loadedTables.where((table) => !table.isFree).map((table) async {
        try {
          final order = await _orderRepository.getOpenOrderByTable(table.id);
          nextCounts[table.id] = _selectionCountForOrder(order);
        } catch (_) {
          nextCounts[table.id] = table.activeOrdersCount;
        }
      }),
    );

    _openOrderSelectionCountByTable
      ..clear()
      ..addAll(nextCounts);
  }

  int _selectionCountForOrder(Order? order) {
    if (order == null) {
      return 0;
    }

    final activeSelections = order.selections
        .where(
          (selection) => !selection.isCancelled && selection.hasVisibleItems,
        )
        .length;

    if (activeSelections > 0) {
      return activeSelections;
    }

    return order.items.fold<int>(0, (sum, item) => sum + item.quantity);
  }
}
