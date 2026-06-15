class OfflineUser {
  OfflineUser({
    required this.userId,
    required this.name,
    required this.role,
    required this.pinHash,
    required this.isActive,
    required this.lastUpdated,
  });

  final int userId;
  final String name;
  final String role;
  final String pinHash;
  final bool isActive;
  final DateTime lastUpdated;

  factory OfflineUser.fromJson(Map<String, dynamic> json) => OfflineUser(
        userId: json['userId'] as int,
        name: json['name'] as String,
        role: json['role'] as String,
        pinHash: json['pinHash'] as String,
        isActive: json['isActive'] as bool,
        lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      );
}
