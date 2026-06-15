import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/kitchen/kitchen_ticket.dart';

class KitchenService {
  final _client = ApiClient.instance.dio;

  Future<List<KitchenTicket>> getTickets() async {
    try {
      final response = await _client.get(ApiConstants.kitchenTickets);
      return (response.data as List<dynamic>)
          .map((item) => KitchenTicket.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<KitchenTicket> updateStatus(int id, int status) async {
    try {
      final response = await _client.put(
        '${ApiConstants.kitchenTickets}/$id/status',
        data: {'status': status},
      );
      return KitchenTicket.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }
}
