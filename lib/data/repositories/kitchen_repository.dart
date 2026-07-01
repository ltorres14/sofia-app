import '../models/kitchen/kitchen_ticket.dart';
import '../services/kitchen_service.dart';

class KitchenRepository {
  KitchenRepository({KitchenService? service})
    : _service = service ?? KitchenService();

  final KitchenService _service;

  Future<List<KitchenTicket>> getTickets() => _service.getTickets();

  Future<KitchenTicket> updateStatus(int id, int status) =>
      _service.updateStatus(id, status);

  Future<void> markSelectionPreparing(int ticketId, int selectionId) =>
      _service.markSelectionPreparing(ticketId, selectionId);

  Future<void> markSelectionReady(int ticketId, int selectionId) =>
      _service.markSelectionReady(ticketId, selectionId);
}
