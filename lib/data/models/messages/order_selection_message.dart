class OrderSelectionMessage {
  OrderSelectionMessage({
    required this.id,
    required this.orderId,
    required this.orderSelectionId,
    required this.restaurantTableId,
    this.tableName,
    this.tableNumber,
    this.selectionSequenceNumber,
    required this.senderUserId,
    required this.senderName,
    this.targetUserId,
    this.targetUserName,
    required this.messageType,
    this.previousMessage,
    this.newMessage,
    required this.message,
    required this.createdAt,
    this.isReadByCurrentUser = false,
  });

  final int id;
  final int orderId;
  final int orderSelectionId;
  final int restaurantTableId;
  final String? tableName;
  final int? tableNumber;
  final int? selectionSequenceNumber;
  final int senderUserId;
  final String senderName;
  final int? targetUserId;
  final String? targetUserName;
  final String messageType;
  final String? previousMessage;
  final String? newMessage;
  final String message;
  final DateTime createdAt;
  final bool isReadByCurrentUser;

  bool get isCommentUpdated => _normalizedType == 'commentupdated';

  String get previewTitle {
    if (isCommentUpdated) {
      return 'Comentario actualizado';
    }

    return message;
  }

  String? get previousMessageText => _normalizeText(previousMessage);
  String? get newMessageText => _normalizeText(newMessage);
  String get messageText => _normalizeText(message) ?? '';
  String get selectionLabel => selectionSequenceNumber != null
      ? 'Selección #$selectionSequenceNumber'
      : 'Selección';
  String get tableLabel {
    final normalizedTableName = _normalizeText(tableName);
    if (normalizedTableName != null) {
      return normalizedTableName;
    }

    if (tableNumber != null) {
      return 'Mesa $tableNumber';
    }

    return 'Mesa';
  }

  factory OrderSelectionMessage.fromJson(Map<String, dynamic> json) {
    return OrderSelectionMessage(
      id: _readInt(json, const ['id', 'Id']),
      orderId: _readInt(json, const ['orderId', 'OrderId']),
      orderSelectionId: _readInt(json, const [
        'orderSelectionId',
        'OrderSelectionId',
      ]),
      restaurantTableId: _readInt(json, const [
        'restaurantTableId',
        'RestaurantTableId',
      ]),
      tableName:
          _readString(json, const ['tableName', 'TableName']) ??
          _readString(json, const ['restaurantTableName']),
      tableNumber: _readNullableInt(json, const ['tableNumber', 'TableNumber']),
      selectionSequenceNumber: _readNullableInt(json, const [
        'selectionSequenceNumber',
        'SelectionSequenceNumber',
      ]),
      senderUserId: _readInt(json, const ['senderUserId', 'SenderUserId']),
      senderName:
          _readString(json, const ['senderName', 'SenderName']) ?? 'Usuario',
      targetUserId: _readNullableInt(json, const [
        'targetUserId',
        'TargetUserId',
      ]),
      targetUserName: _readString(json, const [
        'targetUserName',
        'TargetUserName',
      ]),
      messageType:
          _readString(json, const ['messageType', 'MessageType']) ??
          'ManualMessage',
      previousMessage: _readString(json, const [
        'previousMessage',
        'PreviousMessage',
      ]),
      newMessage: _readString(json, const ['newMessage', 'NewMessage']),
      message: _readString(json, const ['message', 'Message']) ?? '',
      createdAt:
          DateTime.tryParse(
            _readString(json, const ['createdAt', 'CreatedAt']) ?? '',
          ) ??
          DateTime.now(),
      isReadByCurrentUser:
          _readBool(json, const [
            'isReadByCurrentUser',
            'IsReadByCurrentUser',
          ]) ??
          false,
    );
  }

  OrderSelectionMessage copyWith({
    int? id,
    int? orderId,
    int? orderSelectionId,
    int? restaurantTableId,
    String? tableName,
    int? tableNumber,
    int? selectionSequenceNumber,
    int? senderUserId,
    String? senderName,
    int? targetUserId,
    String? targetUserName,
    String? messageType,
    String? previousMessage,
    String? newMessage,
    String? message,
    DateTime? createdAt,
    bool? isReadByCurrentUser,
  }) {
    return OrderSelectionMessage(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      orderSelectionId: orderSelectionId ?? this.orderSelectionId,
      restaurantTableId: restaurantTableId ?? this.restaurantTableId,
      tableName: tableName ?? this.tableName,
      tableNumber: tableNumber ?? this.tableNumber,
      selectionSequenceNumber:
          selectionSequenceNumber ?? this.selectionSequenceNumber,
      senderUserId: senderUserId ?? this.senderUserId,
      senderName: senderName ?? this.senderName,
      targetUserId: targetUserId ?? this.targetUserId,
      targetUserName: targetUserName ?? this.targetUserName,
      messageType: messageType ?? this.messageType,
      previousMessage: previousMessage ?? this.previousMessage,
      newMessage: newMessage ?? this.newMessage,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isReadByCurrentUser: isReadByCurrentUser ?? this.isReadByCurrentUser,
    );
  }

  String get _normalizedType =>
      messageType.trim().toLowerCase().replaceAll('_', '');

  static String? _normalizeText(String? value) {
    final normalized = value?.trim() ?? '';
    return normalized.isEmpty ? null : normalized;
  }

  static String? _readString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is String && value.trim().isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  static int _readInt(Map<String, dynamic> json, List<String> keys) {
    return _readNullableInt(json, keys) ?? 0;
  }

  static int? _readNullableInt(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is int) {
        return value;
      }
      if (value is num) {
        return value.toInt();
      }
      if (value is String) {
        final parsed = int.tryParse(value);
        if (parsed != null) {
          return parsed;
        }
      }
    }

    return null;
  }

  static bool? _readBool(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is bool) {
        return value;
      }
      if (value is num) {
        return value != 0;
      }
      if (value is String) {
        final normalized = value.trim().toLowerCase();
        if (normalized == 'true') {
          return true;
        }
        if (normalized == 'false') {
          return false;
        }
      }
    }

    return null;
  }
}
