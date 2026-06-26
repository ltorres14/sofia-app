import '../models/cash_cut/cash_cut.dart';
import '../models/cash_cut/today_sales.dart';
import '../services/cash_cut_service.dart';

class CashCutRepository {
  CashCutRepository({CashCutService? service})
    : _service = service ?? CashCutService();

  final CashCutService _service;

  bool get supportsCloseToday => _service.supportsCloseToday;

  String get closeTodayUnavailableMessage =>
      CashCutService.closeTodayUnavailableMessage;

  Future<CashCut> getToday() => _service.getToday();
  Future<TodaySalesResponse> getTodaySales() => _service.getTodaySales();

  Future<CashCut> closeToday() => _service.closeToday();
}
