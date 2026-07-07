import '../models/messages/order_selection_message.dart';
import '../services/order_selection_message_service.dart';

class OrderSelectionMessageRepository {
  OrderSelectionMessageRepository({OrderSelectionMessageService? service})
    : _service = service ?? OrderSelectionMessageService();

  final OrderSelectionMessageService _service;

  Future<List<OrderSelectionMessage>> getUnreadMessages() =>
      _service.getUnreadMessages();

  Future<List<OrderSelectionMessage>> getSelectionMessages(
    int orderSelectionId,
  ) => _service.getSelectionMessages(orderSelectionId);

  Future<void> markAsRead(int messageId) => _service.markAsRead(messageId);

  Future<void> markSelectionAsRead(int orderSelectionId) =>
      _service.markSelectionAsRead(orderSelectionId);

  Future<OrderSelectionMessage> createManualMessage({
    required int orderSelectionId,
    required String message,
    int? targetUserId,
  }) => _service.createManualMessage(
    orderSelectionId: orderSelectionId,
    message: message,
    targetUserId: targetUserId,
  );
}
