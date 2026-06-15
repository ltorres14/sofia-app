import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../models/cash_cut/cash_cut.dart';

class CashCutService {
  final _client = ApiClient.instance.dio;

  Future<CashCut> getToday() async {
    try {
      final response = await _client.get(ApiConstants.cashCutToday);
      return CashCut.fromJson(response.data as Map<String, dynamic>);
    } catch (error) {
      ApiClient.instance.parseError(error);
    }
  }
}
