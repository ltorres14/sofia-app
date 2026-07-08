import 'dart:async';

import 'package:signalr_netcore/signalr_client.dart';

import '../../core/constants/api_constants.dart';
import '../../core/storage/secure_storage_service.dart';
import '../models/kitchen/kitchen_ticket.dart';
import '../models/messages/order_selection_message.dart';

class KitchenRealtimeService {
  HubConnection? _hubConnection;
  final StreamController<OrderSelectionMessage> _messageController =
      StreamController<OrderSelectionMessage>.broadcast();
  final StreamController<KitchenTicket> _ticketController =
      StreamController<KitchenTicket>.broadcast();
  int _activeConsumers = 0;

  Stream<OrderSelectionMessage> get messages => _messageController.stream;
  Stream<KitchenTicket> get tickets => _ticketController.stream;
  bool get isConnected => _hubConnection?.state == HubConnectionState.Connected;

  Future<void> start() async {
    _activeConsumers++;

    final token = await SecureStorageService.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    _hubConnection ??= _buildConnection();
    _registerHandlers(_hubConnection!);

    final state = _hubConnection!.state;
    if (state == HubConnectionState.Connected ||
        state == HubConnectionState.Connecting ||
        state == HubConnectionState.Reconnecting) {
      return;
    }

    await _hubConnection!.start();
  }

  Future<void> stop() async {
    if (_activeConsumers > 0) {
      _activeConsumers--;
    }

    if (_activeConsumers > 0) {
      return;
    }

    final connection = _hubConnection;
    if (connection == null) {
      return;
    }

    if (connection.state != HubConnectionState.Disconnected) {
      await connection.stop();
    }
  }

  Future<void> dispose() async {
    await stop();
    await _ticketController.close();
    await _messageController.close();
  }

  HubConnection _buildConnection() {
    final options = HttpConnectionOptions(
      accessTokenFactory: () async =>
          await SecureStorageService.getToken() ?? '',
    );

    return HubConnectionBuilder()
        .withUrl(ApiConstants.kitchenHub, options: options)
        .withAutomaticReconnect(retryDelays: [2000, 5000, 10000, 20000])
        .build();
  }

  void _registerHandlers(HubConnection connection) {
    connection.off('orderSelectionMessageCreated');
    connection.on('orderSelectionMessageCreated', (arguments) {
      if (arguments == null || arguments.isEmpty) {
        return;
      }

      final payload = arguments.first;
      if (payload is! Map) {
        return;
      }

      final normalizedPayload = Map<String, dynamic>.from(payload);
      _messageController.add(OrderSelectionMessage.fromJson(normalizedPayload));
    });

    connection.off('KitchenTicketCreated');
    connection.on('KitchenTicketCreated', _handleTicketEvent);

    connection.off('KitchenTicketUpdated');
    connection.on('KitchenTicketUpdated', _handleTicketEvent);
  }

  void _handleTicketEvent(List<Object?>? arguments) {
    if (arguments == null || arguments.isEmpty) {
      return;
    }

    final payload = arguments.first;
    if (payload is! Map) {
      return;
    }

    final normalizedPayload = Map<String, dynamic>.from(payload);
    _ticketController.add(KitchenTicket.fromJson(normalizedPayload));
  }
}
