import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
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
  bool isLoading = false;
  String? errorMessage;
  String? actionErrorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      tables = await _tableRepository.getTables();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
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

  void clearActionError() {
    if (actionErrorMessage == null) return;
    actionErrorMessage = null;
    notifyListeners();
  }
}
