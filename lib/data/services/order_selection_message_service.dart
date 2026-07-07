import 'package:dio/dio.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/messages/order_selection_message.dart';

class OrderSelectionMessageService {
  final _client = ApiClient.instance.dio;

  Future<List<OrderSelectionMessage>> getUnreadMessages() async {
    try {
      final response = await _client.get(
        '${ApiConstants.orderSelectionMessages}/unread',
      );
      final data = response.data as List<dynamic>;
      return data
          .map(
            (item) =>
                OrderSelectionMessage.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const [];
      }
      ApiClient.instance.parseError(error);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<List<OrderSelectionMessage>> getSelectionMessages(
    int orderSelectionId,
  ) async {
    try {
      final response = await _client.get(
        '${ApiConstants.orderSelectionMessages}/selection/$orderSelectionId',
      );
      final data = response.data as List<dynamic>;
      return data
          .map(
            (item) =>
                OrderSelectionMessage.fromJson(item as Map<String, dynamic>),
          )
          .toList();
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return const [];
      }
      ApiClient.instance.parseError(error);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<void> markAsRead(int messageId) async {
    try {
      await _client.post(
        '${ApiConstants.orderSelectionMessages}/$messageId/read',
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return;
      }
      ApiClient.instance.parseError(error);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<void> markSelectionAsRead(int orderSelectionId) async {
    try {
      await _client.post(
        '${ApiConstants.orderSelectionMessages}/selection/$orderSelectionId/read-all',
      );
    } on DioException catch (error) {
      if (error.response?.statusCode == 404) {
        return;
      }
      ApiClient.instance.parseError(error);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }

  Future<OrderSelectionMessage> createManualMessage({
    required int orderSelectionId,
    required String message,
    int? targetUserId,
  }) async {
    try {
      final response = await _client.post(
        ApiConstants.orderSelectionMessages,
        data: {
          'orderSelectionId': orderSelectionId,
          'message': message.trim(),
          'targetUserId': targetUserId,
        },
      );
      return OrderSelectionMessage.fromJson(
        response.data as Map<String, dynamic>,
      );
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }
}
