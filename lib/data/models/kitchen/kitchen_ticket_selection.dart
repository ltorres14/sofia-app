import 'kitchen_ticket_item.dart';

class KitchenTicketSelection {
  static const int draftStatus = 0;
  static const int pendingStatus = 1;
  static const int preparingStatus = 2;
  static const int readyStatus = 3;
  static const int cancelledStatus = 4;

  KitchenTicketSelection({
    required this.orderSelectionId,
    required this.status,
    required this.sequenceNumber,
    required this.label,
    this.comment,
    this.notes,
    required this.items,
  });

  final int orderSelectionId;
  final int status;
  final int sequenceNumber;
  final String label;
  final String? comment;
  final String? notes;
  final List<KitchenTicketItem> items;

  bool get isDraft => status == draftStatus;
  bool get isCancelled => status == cancelledStatus;
  bool get isVisibleInKitchen => !isDraft && !isCancelled;
  String get displayComment => _firstNonEmpty(comment, notes);
  bool get hasComment => displayComment.isNotEmpty;

  factory KitchenTicketSelection.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map((item) => KitchenTicketItem.fromJson(item as Map<String, dynamic>))
        .toList();

    return KitchenTicketSelection(
      orderSelectionId:
          (json['orderSelectionId'] as int?) ??
          (json['selectionId'] as int?) ??
          (json['id'] as int?) ??
          0,
      status: _parseStatus(json['status']),
      sequenceNumber: (json['sequenceNumber'] as int?) ?? 0,
      label: json['label'] as String? ?? '',
      comment: json['comment'] as String? ?? json['notes'] as String?,
      notes: json['notes'] as String?,
      items: items,
    );
  }

  static int _parseStatus(dynamic value) {
    if (value is int) {
      return value;
    }

    final normalized = value?.toString().trim().toLowerCase() ?? '';
    switch (normalized) {
      case 'draft':
      case 'borrador':
        return draftStatus;
      case 'pending':
      case 'pendiente':
        return pendingStatus;
      case 'preparing':
      case 'preparando':
        return preparingStatus;
      case 'ready':
      case 'lista':
      case 'listo':
        return readyStatus;
      case 'cancelled':
      case 'canceled':
      case 'cancelada':
      case 'cancelado':
        return cancelledStatus;
      default:
        return pendingStatus;
    }
  }

  static String _firstNonEmpty(String? primary, String? fallback) {
    final normalizedPrimary = primary?.trim() ?? '';
    if (normalizedPrimary.isNotEmpty) {
      return normalizedPrimary;
    }

    return fallback?.trim() ?? '';
  }
}
