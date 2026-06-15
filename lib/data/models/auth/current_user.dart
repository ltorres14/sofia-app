class CurrentUser {
  CurrentUser({
    required this.userId,
    required this.name,
    required this.role,
  });

  final int userId;
  final String name;
  final String role;

  factory CurrentUser.fromJson(Map<String, dynamic> json) => CurrentUser(
        userId: json['userId'] as int,
        name: json['name'] as String,
        role: json['role'] as String,
      );
}
