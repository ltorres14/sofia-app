import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/activity/recent_activity_item.dart';
import '../../../data/models/kitchen/kitchen_ticket.dart';
import '../../../data/models/kitchen/kitchen_ticket_selection.dart';
import '../../../data/repositories/kitchen_repository.dart';

class KitchenViewModel extends ChangeNotifier {
  KitchenViewModel({required KitchenRepository kitchenRepository})
    : _kitchenRepository = kitchenRepository;

  final KitchenRepository _kitchenRepository;

  List<KitchenTicket> tickets = [];
  List<RecentActivityItem> recentActivities = [];
  bool isLoading = false;
  bool isRecentActivityLoading = false;
  String? errorMessage;
  String? actionErrorMessage;
  String? recentActivityErrorMessage;
  final Set<int> _loadingLegacyTicketIds = <int>{};
  final Set<String> _loadingSelectionKeys = <String>{};

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      tickets = (await _kitchenRepository.getTickets())
          .map(_filterHiddenSelections)
          .where(
            (ticket) => ticket.selections.isNotEmpty || ticket.items.isNotEmpty,
          )
          .toList();
      await _loadRecentActivity(
        showLoadingState: showLoading && recentActivities.isEmpty,
        notify: false,
      );
      errorMessage = null;
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      if (showLoading) {
        errorMessage = message;
      } else {
        actionErrorMessage = message;
      }
    } finally {
      if (showLoading) {
        isLoading = false;
      }
      notifyListeners();
    }
  }

  Future<void> advanceStatus(KitchenTicket ticket) async {
    if (ticket.selections.isNotEmpty ||
        _loadingLegacyTicketIds.contains(ticket.id) ||
        ticket.status >= 3) {
      return;
    }

    final nextStatus = ticket.status == 1 ? 2 : 3;
    _loadingLegacyTicketIds.add(ticket.id);
    actionErrorMessage = null;
    notifyListeners();

    try {
      await _kitchenRepository.updateStatus(ticket.id, nextStatus);
      await load(showLoading: false);
    } catch (error) {
      await _handleActionError(error);
    } finally {
      _loadingLegacyTicketIds.remove(ticket.id);
      notifyListeners();
    }
  }

  Future<void> advanceSelectionStatus(
    KitchenTicket ticket,
    KitchenTicketSelection selection,
  ) async {
    if (selection.status >= 3) {
      return;
    }

    final selectionKey = _selectionKey(ticket.id, selection.orderSelectionId);
    if (_loadingSelectionKeys.contains(selectionKey)) {
      return;
    }

    _loadingSelectionKeys.add(selectionKey);
    actionErrorMessage = null;
    notifyListeners();

    try {
      if (selection.status == 1) {
        await _kitchenRepository.markSelectionPreparing(
          ticket.id,
          selection.orderSelectionId,
        );
      } else {
        await _kitchenRepository.markSelectionReady(
          ticket.id,
          selection.orderSelectionId,
        );
      }
      await load(showLoading: false);
    } catch (error) {
      await _handleActionError(error);
    } finally {
      _loadingSelectionKeys.remove(selectionKey);
      notifyListeners();
    }
  }

  bool isLegacyActionLoading(int ticketId) {
    return _loadingLegacyTicketIds.contains(ticketId);
  }

  bool isSelectionActionLoading(int ticketId, int selectionId) {
    return _loadingSelectionKeys.contains(_selectionKey(ticketId, selectionId));
  }

  void clearActionError() {
    if (actionErrorMessage == null) {
      return;
    }

    actionErrorMessage = null;
    notifyListeners();
  }

  Future<void> _handleActionError(Object error) async {
    final message = error.toString().replaceFirst('Exception: ', '');

    if (error is ApiException && error.statusCode == 409) {
      actionErrorMessage = message.isNotEmpty
          ? '$message Se actualizó la cocina.'
          : 'La selección ya cambió de estado. Se actualizó la cocina.';
      try {
        tickets = await _kitchenRepository.getTickets();
        errorMessage = null;
      } catch (_) {}
      return;
    }

    actionErrorMessage = message;
  }

  String _selectionKey(int ticketId, int selectionId) {
    return '$ticketId:$selectionId';
  }

  KitchenTicket _filterHiddenSelections(KitchenTicket ticket) {
    final visibleSelections = ticket.selections
        .where((selection) => selection.isVisibleInKitchen)
        .toList();

    return KitchenTicket(
      id: ticket.id,
      orderId: ticket.orderId,
      tableName: ticket.tableName,
      status: ticket.status,
      createdAt: ticket.createdAt,
      selections: visibleSelections,
      legacyItems: ticket.legacyItems,
    );
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
      recentActivities = await _kitchenRepository.getRecentActivity(limit: 20);
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
}
