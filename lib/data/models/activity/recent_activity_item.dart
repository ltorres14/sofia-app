class RecentActivityItem {
  const RecentActivityItem({
    required this.eventType,
    required this.description,
    required this.tableName,
    required this.activityAt,
    this.statusLabel,
    this.total,
    this.orderId,
    this.ticketId,
    this.selectionId,
    this.actorName,
    this.selectionSequenceNumber,
    this.selectionLabel,
    this.selectionComment,
    this.itemsSummary,
    this.paymentMethod,
    this.paymentComments,
    this.eventGroup,
  });

  final String eventType;
  final String description;
  final String tableName;
  final String? statusLabel;
  final DateTime activityAt;
  final double? total;
  final int? orderId;
  final int? ticketId;
  final int? selectionId;
  final String? actorName;
  final int? selectionSequenceNumber;
  final String? selectionLabel;
  final String? selectionComment;
  final String? itemsSummary;
  final String? paymentMethod;
  final String? paymentComments;
  final String? eventGroup;

  bool get hasStatus => _hasText(statusLabel);
  bool get hasTotal => total != null;
  bool get hasMeaningfulTotal => total != null && total! > 0;
  bool get hasActorName => _hasText(actorName);
  bool get hasSelectionLabel => _hasText(selectionLabel);
  bool get hasSelectionComment => _hasText(selectionComment);
  bool get hasItemsSummary => _hasText(itemsSummary);
  bool get hasPaymentMethod => _hasText(paymentMethod);
  bool get hasPaymentComments => _hasText(paymentComments);

  String get normalizedEventType => eventType.trim().toLowerCase();
  String get normalizedEventGroup =>
      (eventGroup ?? _defaultEventGroupForEventType(eventType))
          .trim()
          .toLowerCase();

  factory RecentActivityItem.fromJson(Map<String, dynamic> json) {
    final eventType =
        _readString(json, const [
          'eventType',
          'EventType',
          'activityType',
          'ActivityType',
          'type',
          'Type',
          'event',
          'Event',
        ]) ??
        '';

    final description =
        _readString(json, const [
          'description',
          'Description',
          'message',
          'Message',
          'title',
          'Title',
          'label',
          'Label',
        ]) ??
        _defaultDescriptionForEventType(eventType);

    final tableName =
        _readString(json, const [
          'tableName',
          'TableName',
          'table',
          'Table',
          'mesa',
          'Mesa',
        ]) ??
        _readNestedString(json['table'], const [
          'name',
          'Name',
          'label',
          'Label',
        ]) ??
        'Mesa';

    final statusLabel =
        _readString(json, const [
          'statusLabel',
          'StatusLabel',
          'status',
          'Status',
          'state',
          'State',
        ]) ??
        _readNestedString(json['status'], const [
          'label',
          'Label',
          'name',
          'Name',
        ]) ??
        _defaultStatusForEventType(eventType);

    final activityAtRaw = _readValue(json, const [
      'activityAt',
      'ActivityAt',
      'createdAt',
      'CreatedAt',
      'timestamp',
      'Timestamp',
      'date',
      'Date',
    ]);

    return RecentActivityItem(
      eventType: eventType,
      description: description,
      tableName: tableName,
      statusLabel: statusLabel,
      activityAt: _parseDateTime(activityAtRaw) ?? DateTime.now(),
      total: _parseDouble(
        _readValue(json, const ['total', 'Total', 'amount', 'Amount']),
      ),
      orderId: _parseInt(_readValue(json, const ['orderId', 'OrderId'])),
      ticketId: _parseInt(_readValue(json, const ['ticketId', 'TicketId'])),
      selectionId: _parseInt(
        _readValue(json, const [
          'selectionId',
          'SelectionId',
          'orderSelectionId',
        ]),
      ),
      actorName:
          _readString(json, const ['actorName', 'ActorName']) ??
          _readNestedString(json['actor'], const [
            'name',
            'Name',
            'fullName',
            'FullName',
            'label',
            'Label',
          ]) ??
          _readNestedString(json['user'], const [
            'name',
            'Name',
            'fullName',
            'FullName',
            'label',
            'Label',
          ]),
      selectionSequenceNumber: _parseInt(
        _readValue(json, const [
          'selectionSequenceNumber',
          'SelectionSequenceNumber',
          'selectionNumber',
          'SelectionNumber',
          'sequenceNumber',
          'SequenceNumber',
        ]),
      ),
      selectionLabel:
          _readString(json, const ['selectionLabel', 'SelectionLabel']) ??
          _readNestedString(json['selection'], const [
            'label',
            'Label',
            'name',
            'Name',
            'title',
            'Title',
          ]),
      selectionComment:
          _readString(json, const ['selectionComment', 'SelectionComment']) ??
          _readNestedString(json['selection'], const [
            'comment',
            'Comment',
            'notes',
            'Notes',
          ]),
      itemsSummary:
          _readString(json, const ['itemsSummary', 'ItemsSummary']) ??
          _readNestedString(json['items'], const [
            'summary',
            'Summary',
            'label',
            'Label',
          ]),
      paymentMethod:
          _readString(json, const ['paymentMethod', 'PaymentMethod']) ??
          _readNestedString(json['payment'], const [
            'method',
            'Method',
            'label',
            'Label',
            'name',
            'Name',
          ]),
      paymentComments:
          _readString(json, const ['paymentComments', 'PaymentComments']) ??
          _readNestedString(json['payment'], const [
            'comments',
            'Comments',
            'comment',
            'Comment',
            'notes',
            'Notes',
          ]),
      eventGroup:
          _readString(json, const ['eventGroup', 'EventGroup']) ??
          _readString(json, const ['group', 'Group', 'category', 'Category']) ??
          _defaultEventGroupForEventType(eventType),
    );
  }

  static dynamic _readValue(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      if (json.containsKey(key) && json[key] != null) {
        return json[key];
      }
    }

    return null;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    final value = _readValue(json, keys);
    if (value == null) {
      return null;
    }

    if (value is String) {
      final normalized = value.trim();
      return normalized.isEmpty ? null : normalized;
    }

    if (value is Map<String, dynamic>) {
      return _readNestedString(value, const [
        'label',
        'Label',
        'name',
        'Name',
        'value',
        'Value',
      ]);
    }

    final normalized = value.toString().trim();
    return normalized.isEmpty ? null : normalized;
  }

  static String? _readNestedString(dynamic value, List<String> keys) {
    if (value is! Map<String, dynamic>) {
      return null;
    }

    for (final key in keys) {
      final nested = value[key];
      if (nested is String && nested.trim().isNotEmpty) {
        return nested.trim();
      }
    }

    return null;
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value.trim());
    }

    return null;
  }

  static double? _parseDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    if (value is String) {
      return double.tryParse(value.trim());
    }

    return null;
  }

  static int? _parseInt(dynamic value) {
    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    if (value is String) {
      return int.tryParse(value.trim());
    }

    return null;
  }

  static String _defaultDescriptionForEventType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'order_opened':
        return 'Orden abierta';
      case 'order_selection_created':
        return 'Selección agregada';
      case 'order_selection_updated':
        return 'Selección actualizada';
      case 'order_selection_comment_updated':
        return 'Comentario actualizado';
      case 'order_selection_cancelled':
        return 'Selección cancelada';
      case 'order_sent_to_kitchen':
        return 'Orden enviada a cocina';
      case 'order_bill_requested':
        return 'Cuenta solicitada';
      case 'order_paid':
        return 'Orden pagada';
      case 'kitchen_ticket_sent':
        return 'Ticket enviado a cocina';
      case 'kitchen_ticket_preparing':
        return 'Ticket en preparación';
      case 'kitchen_ticket_ready':
        return 'Ticket listo';
      case 'kitchen_ticket_status_updated':
        return 'Estado de ticket actualizado';
      default:
        return _humanizeEventType(value);
    }
  }

  static String? _defaultStatusForEventType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'order_opened':
        return 'Abierta';
      case 'order_selection_cancelled':
        return 'Cancelada';
      case 'order_sent_to_kitchen':
        return 'Enviada';
      case 'order_bill_requested':
        return 'Cuenta solicitada';
      case 'order_paid':
        return 'Pagada';
      case 'kitchen_ticket_sent':
        return 'Enviada';
      case 'kitchen_ticket_preparing':
        return 'Preparando';
      case 'kitchen_ticket_ready':
        return 'Lista';
      default:
        return null;
    }
  }

  static String _defaultEventGroupForEventType(String value) {
    switch (value.trim().toLowerCase()) {
      case 'order_selection_created':
      case 'order_selection_updated':
      case 'order_selection_comment_updated':
      case 'order_selection_cancelled':
        return 'selection';
      case 'order_sent_to_kitchen':
      case 'kitchen_ticket_sent':
      case 'kitchen_ticket_preparing':
      case 'kitchen_ticket_ready':
      case 'kitchen_ticket_status_updated':
        return 'kitchen';
      case 'order_opened':
        return 'table';
      case 'order_bill_requested':
        return 'billing';
      case 'order_paid':
        return 'payment';
      default:
        return '';
    }
  }

  static String _humanizeEventType(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) {
      return 'Movimiento reciente';
    }

    final parts = normalized.split('_').where((part) => part.isNotEmpty);
    final words = parts.map((part) {
      final lower = part.toLowerCase();
      return '${lower.substring(0, 1).toUpperCase()}${lower.substring(1)}';
    }).toList();

    if (words.isEmpty) {
      return 'Movimiento reciente';
    }

    return words.join(' ');
  }

  static bool _hasText(String? value) => value?.trim().isNotEmpty ?? false;
}
