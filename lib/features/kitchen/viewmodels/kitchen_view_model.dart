import 'package:flutter/material.dart';

import '../../../data/models/kitchen/kitchen_ticket.dart';
import '../../../data/repositories/kitchen_repository.dart';

class KitchenViewModel extends ChangeNotifier {
  KitchenViewModel({required KitchenRepository kitchenRepository})
      : _kitchenRepository = kitchenRepository;

  final KitchenRepository _kitchenRepository;

  List<KitchenTicket> tickets = [];
  bool isLoading = false;
  String? errorMessage;

  Future<void> load() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      tickets = await _kitchenRepository.getTickets();
    } catch (error) {
      errorMessage = error.toString().replaceFirst('Exception: ', '');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> advanceStatus(KitchenTicket ticket) async {
    final nextStatus = ticket.status == 1 ? 2 : 3;
    await _kitchenRepository.updateStatus(ticket.id, nextStatus);
    await load();
  }
}
