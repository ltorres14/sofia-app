import 'order_selection_item.dart';

class OrderSelection {
  static const int draftStatus = 1;
  static const int pendingStatus = 3;
  static const int cancelledStatus = 4;
  static const int preparingStatus = 5;
  static const int readyStatus = 6;

  OrderSelection({
    required this.id,
    required this.sequenceNumber,
    required this.label,
    this.comment,
    this.notes,
    required this.status,
    this.canEdit,
    this.canDelete,
    required this.createdAt,
    required this.total,
    required this.items,
  });

  final int id;
  final int sequenceNumber;
  final String label;
  final String? comment;
  final String? notes;
  final int status;
  final bool? canEdit;
  final bool? canDelete;
  final DateTime createdAt;
  final double total;
  final List<OrderSelectionItem> items;

  bool get isLocalDraft => id <= 0;
  bool get isDraft => status == draftStatus;
  bool get isPending => status == pendingStatus;
  bool get isPreparing => status == preparingStatus;
  bool get isReady => status == readyStatus;
  bool get isCancelled => status == cancelledStatus;
  bool get isEditableByStatus => isDraft || isPending;
  bool get resolvedCanEdit => canEdit ?? isEditableByStatus;
  bool get resolvedCanDelete => canDelete ?? isEditableByStatus;
  bool get hasVisibleItems =>
      items.any((item) => item.quantity > 0) || total > 0;
  String get displayComment => _firstNonEmpty(comment, notes);
  bool get hasComment => displayComment.isNotEmpty;

  String get statusLabel {
    switch (status) {
      case draftStatus:
        return 'Borrador';
      case pendingStatus:
        return 'Enviada';
      case preparingStatus:
        return 'Preparando';
      case readyStatus:
        return 'Lista';
      case cancelledStatus:
        return 'Cancelada';
      default:
        return 'Borrador';
    }
  }

  factory OrderSelection.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? const [])
        .map(
          (item) => OrderSelectionItem.fromJson(item as Map<String, dynamic>),
        )
        .toList();

    return OrderSelection(
      id: (json['id'] as int?) ?? 0,
      sequenceNumber: json['sequenceNumber'] as int? ?? 0,
      label: json['label'] as String? ?? '',
      comment: json['comment'] as String? ?? json['notes'] as String?,
      notes: json['notes'] as String?,
      status: _parseStatus(json['status']),
      canEdit: _parseNullableBool(json['canEdit']),
      canDelete: _parseNullableBool(json['canDelete']),
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      total:
          (json['total'] as num?)?.toDouble() ??
          items.fold<double>(0, (sum, item) => sum + item.total),
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sequenceNumber': sequenceNumber,
    'label': label,
    'comment': comment,
    'notes': notes,
    'status': status,
    'canEdit': canEdit,
    'canDelete': canDelete,
    'createdAt': createdAt.toIso8601String(),
    'total': total,
    'items': items.map((item) => item.toJson()).toList(),
  };

  OrderSelection copyWith({
    int? id,
    int? sequenceNumber,
    String? label,
    String? comment,
    String? notes,
    int? status,
    bool? canEdit,
    bool? canDelete,
    DateTime? createdAt,
    double? total,
    List<OrderSelectionItem>? items,
  }) {
    return OrderSelection(
      id: id ?? this.id,
      sequenceNumber: sequenceNumber ?? this.sequenceNumber,
      label: label ?? this.label,
      comment: comment ?? this.comment,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      canEdit: canEdit ?? this.canEdit,
      canDelete: canDelete ?? this.canDelete,
      createdAt: createdAt ?? this.createdAt,
      total: total ?? this.total,
      items: items ?? this.items,
    );
  }

  static int _parseStatus(dynamic value) {
    if (value is int) {
      switch (value) {
        case 0:
        case 1:
          return draftStatus;
        case 3:
          return pendingStatus;
        case 4:
          return cancelledStatus;
        case 5:
          return preparingStatus;
        case 6:
          return readyStatus;
        default:
          return draftStatus;
      }
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
        return draftStatus;
    }
  }

  static bool? _parseNullableBool(dynamic value) {
    if (value is bool) {
      return value;
    }

    if (value is num) {
      return value != 0;
    }

    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }

    return null;
  }

  static String _firstNonEmpty(String? primary, String? fallback) {
    final normalizedPrimary = primary?.trim() ?? '';
    if (normalizedPrimary.isNotEmpty) {
      return normalizedPrimary;
    }

    return fallback?.trim() ?? '';
  }
}
