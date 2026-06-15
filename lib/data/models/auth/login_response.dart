import 'current_user.dart';

class LoginResponse {
  LoginResponse({
    required this.token,
    required this.expiresAt,
    required this.user,
  });

  final String token;
  final DateTime expiresAt;
  final CurrentUser user;

  factory LoginResponse.fromJson(Map<String, dynamic> json) => LoginResponse(
        token: json['token'] as String,
        expiresAt: DateTime.parse(json['expiresAt'] as String),
        user: CurrentUser.fromJson(json['user'] as Map<String, dynamic>),
      );
}
