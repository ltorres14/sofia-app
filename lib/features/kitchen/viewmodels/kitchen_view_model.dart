import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/network/api_exception.dart';
import '../../../data/models/activity/recent_activity_item.dart';
import '../../../data/models/kitchen/kitchen_ticket.dart';
import '../../../data/models/kitchen/kitchen_ticket_selection.dart';
import '../../../data/models/messages/order_selection_message.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/kitchen_repository.dart';
import '../../../data/repositories/order_selection_message_repository.dart';
import '../../../data/services/kitchen_realtime_service.dart';

class KitchenViewModel extends ChangeNotifier {
  KitchenViewModel({
    required KitchenRepository kitchenRepository,
    required OrderSelectionMessageRepository orderSelectionMessageRepository,
    required AuthRepository authRepository,
    required KitchenRealtimeService kitchenRealtimeService,
  }) : _kitchenRepository = kitchenRepository,
       _orderSelectionMessageRepository = orderSelectionMessageRepository,
       _authRepository = authRepository,
       _kitchenRealtimeService = kitchenRealtimeService;

  final KitchenRepository _kitchenRepository;
  final OrderSelectionMessageRepository _orderSelectionMessageRepository;
  final AuthRepository _authRepository;
  final KitchenRealtimeService _kitchenRealtimeService;

  List<KitchenTicket> tickets = [];
  List<RecentActivityItem> recentActivities = [];
  List<OrderSelectionMessage> unreadMessages = [];

  bool isLoading = false;
  bool isRecentActivityLoading = false;
  bool isUnreadLoading = false;

  String? errorMessage;
  String? actionErrorMessage;
  String? recentActivityErrorMessage;
  String? unreadErrorMessage;

  final Set<int> _loadingLegacyTicketIds = <int>{};
  final Set<String> _loadingSelectionKeys = <String>{};
  final Set<int> _loadingSelectionMessageIds = <int>{};
  final Map<int, List<OrderSelectionMessage>> _selectionMessagesBySelectionId =
      <int, List<OrderSelectionMessage>>{};
  final Map<int, String?> _selectionMessageErrorsBySelectionId =
      <int, String?>{};

  StreamSubscription<OrderSelectionMessage>? _messageSubscription;
  bool _realtimeStarted = false;
  int? _activeSelectionHistoryId;

  int get unreadCount => unreadMessages.length;

  bool get hasUnreadMessages => unreadMessages.isNotEmpty;

  Future<void> load({bool showLoading = true}) async {
    if (showLoading) {
      isLoading = true;
      errorMessage = null;
      notifyListeners();
    }

    try {
      final ticketsFuture = _kitchenRepository.getTickets();
      final recentActivityFuture = _kitchenRepository.getRecentActivity(
        limit: 20,
      );
      final unreadFuture = _orderSelectionMessageRepository.getUnreadMessages();

      tickets = (await ticketsFuture)
          .map(_filterHiddenSelections)
          .where(
            (ticket) => ticket.selections.isNotEmpty || ticket.items.isNotEmpty,
          )
          .toList();
      recentActivities = await recentActivityFuture;
      unreadMessages = _sortMessages(await unreadFuture);

      errorMessage = null;
      recentActivityErrorMessage = null;
      unreadErrorMessage = null;
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

  Future<void> startRealtime() async {
    if (_realtimeStarted) {
      return;
    }

    _messageSubscription = _kitchenRealtimeService.messages.listen(
      _handleIncomingMessage,
    );
    _realtimeStarted = true;

    try {
      await _kitchenRealtimeService.start();
    } catch (_) {
      // Polling remains as fallback.
    }
  }

  Future<void> stopRealtime() async {
    await _messageSubscription?.cancel();
    _messageSubscription = null;
    _realtimeStarted = false;

    try {
      await _kitchenRealtimeService.stop();
    } catch (_) {}
  }

  Future<void> advanceStatus(KitchenTicket ticket) async {
    if (ticket.selections.isNotEmpty ||
        _loadingLegacyTicketIds.contains(ticket.id) ||
        ticket.status >= 3) {
      return;
    }

    _loadingLegacyTicketIds.add(ticket.id);
    actionErrorMessage = null;
    notifyListeners();

    try {
      final nextStatus = ticket.status == 1 ? 2 : 3;
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

  Future<void> loadSelectionMessages(
    int orderSelectionId, {
    bool markAsRead = false,
  }) async {
    if (_loadingSelectionMessageIds.contains(orderSelectionId)) {
      return;
    }

    _loadingSelectionMessageIds.add(orderSelectionId);
    _selectionMessageErrorsBySelectionId.remove(orderSelectionId);
    notifyListeners();

    try {
      var messages = await _orderSelectionMessageRepository
          .getSelectionMessages(orderSelectionId);

      if (markAsRead) {
        await _orderSelectionMessageRepository.markSelectionAsRead(
          orderSelectionId,
        );
        messages = messages
            .map((message) => message.copyWith(isReadByCurrentUser: true))
            .toList();
        _markSelectionAsReadLocally(orderSelectionId);
      }

      _selectionMessagesBySelectionId[orderSelectionId] = _sortMessages(
        messages,
        newestFirst: false,
      );
    } catch (error) {
      _selectionMessageErrorsBySelectionId[orderSelectionId] = error
          .toString()
          .replaceFirst('Exception: ', '');
    } finally {
      _loadingSelectionMessageIds.remove(orderSelectionId);
      notifyListeners();
    }
  }

  Future<void> markAsRead(int messageId, int orderSelectionId) async {
    try {
      await _orderSelectionMessageRepository.markAsRead(messageId);
      _markMessageAsReadLocally(messageId, orderSelectionId);
      notifyListeners();
    } catch (_) {}
  }

  Future<void> markSelectionAsRead(int orderSelectionId) async {
    try {
      await _orderSelectionMessageRepository.markSelectionAsRead(
        orderSelectionId,
      );
      _markSelectionAsReadLocally(orderSelectionId);
      notifyListeners();
    } catch (_) {}
  }

  List<OrderSelectionMessage> selectionMessagesFor(int orderSelectionId) {
    return List<OrderSelectionMessage>.unmodifiable(
      _selectionMessagesBySelectionId[orderSelectionId] ?? const [],
    );
  }

  bool isSelectionMessagesLoading(int orderSelectionId) {
    return _loadingSelectionMessageIds.contains(orderSelectionId);
  }

  String? selectionMessagesError(int orderSelectionId) {
    return _selectionMessageErrorsBySelectionId[orderSelectionId];
  }

  int unreadCountForSelection(int orderSelectionId) {
    return unreadMessages
        .where((message) => message.orderSelectionId == orderSelectionId)
        .length;
  }

  OrderSelectionMessage? latestUnreadMessageForSelection(int orderSelectionId) {
    try {
      return unreadMessages.firstWhere(
        (message) => message.orderSelectionId == orderSelectionId,
      );
    } catch (_) {
      return null;
    }
  }

  void setActiveSelectionHistory(int? orderSelectionId) {
    _activeSelectionHistoryId = orderSelectionId;
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
        tickets = (await _kitchenRepository.getTickets())
            .map(_filterHiddenSelections)
            .toList();
        errorMessage = null;
      } catch (_) {}
      return;
    }

    actionErrorMessage = message;
  }

  void _handleIncomingMessage(OrderSelectionMessage message) {
    final currentUserId = _authRepository.currentUser?.userId;

    if (_activeSelectionHistoryId == message.orderSelectionId) {
      final readMessage = message.copyWith(isReadByCurrentUser: true);
      _mergeSelectionMessage(readMessage);
      unawaited(markAsRead(message.id, message.orderSelectionId));
      return;
    }

    _mergeSelectionMessage(message);

    if (currentUserId == null || message.senderUserId != currentUserId) {
      unreadMessages = _mergeMessageIntoList(unreadMessages, message);
    }

    notifyListeners();
    unawaited(_refreshTicketsAfterRealtime());
  }

  Future<void> _refreshTicketsAfterRealtime() async {
    try {
      tickets = (await _kitchenRepository.getTickets())
          .map(_filterHiddenSelections)
          .where(
            (ticket) => ticket.selections.isNotEmpty || ticket.items.isNotEmpty,
          )
          .toList();
      notifyListeners();
    } catch (_) {}
  }

  void _markMessageAsReadLocally(int messageId, int orderSelectionId) {
    unreadMessages = unreadMessages
        .where((message) => message.id != messageId)
        .toList();

    final existingMessages = _selectionMessagesBySelectionId[orderSelectionId];
    if (existingMessages == null) {
      return;
    }

    _selectionMessagesBySelectionId[orderSelectionId] = existingMessages
        .map(
          (message) => message.id == messageId
              ? message.copyWith(isReadByCurrentUser: true)
              : message,
        )
        .toList();
  }

  void _markSelectionAsReadLocally(int orderSelectionId) {
    unreadMessages = unreadMessages
        .where((message) => message.orderSelectionId != orderSelectionId)
        .toList();

    final existingMessages = _selectionMessagesBySelectionId[orderSelectionId];
    if (existingMessages == null) {
      return;
    }

    _selectionMessagesBySelectionId[orderSelectionId] = existingMessages
        .map((message) => message.copyWith(isReadByCurrentUser: true))
        .toList();
  }

  void _mergeSelectionMessage(OrderSelectionMessage message) {
    final existing = _selectionMessagesBySelectionId[message.orderSelectionId];
    if (existing == null || existing.isEmpty) {
      _selectionMessagesBySelectionId[message.orderSelectionId] = [message];
      return;
    }

    _selectionMessagesBySelectionId[message.orderSelectionId] = _sortMessages(
      _mergeMessageIntoList(existing, message),
      newestFirst: false,
    );
  }

  List<OrderSelectionMessage> _mergeMessageIntoList(
    List<OrderSelectionMessage> current,
    OrderSelectionMessage incoming,
  ) {
    final updated = <OrderSelectionMessage>[
      for (final message in current)
        if (message.id == incoming.id) incoming else message,
    ];

    final alreadyExists = current.any((message) => message.id == incoming.id);
    if (!alreadyExists) {
      updated.add(incoming);
    }

    return _sortMessages(updated);
  }

  List<OrderSelectionMessage> _sortMessages(
    List<OrderSelectionMessage> messages, {
    bool newestFirst = true,
  }) {
    final sorted = List<OrderSelectionMessage>.from(messages);
    sorted.sort((left, right) {
      final dateComparison = newestFirst
          ? right.createdAt.compareTo(left.createdAt)
          : left.createdAt.compareTo(right.createdAt);
      if (dateComparison != 0) {
        return dateComparison;
      }

      return newestFirst
          ? right.id.compareTo(left.id)
          : left.id.compareTo(right.id);
    });
    return sorted;
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

  @override
  void dispose() {
    unawaited(stopRealtime());
    super.dispose();
  }
}
