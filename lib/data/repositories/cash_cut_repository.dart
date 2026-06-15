import '../models/cash_cut/cash_cut.dart';
import '../services/cash_cut_service.dart';

class CashCutRepository {
  CashCutRepository({CashCutService? service}) : _service = service ?? CashCutService();

  final CashCutService _service;

  Future<CashCut> getToday() => _service.getToday();
}
