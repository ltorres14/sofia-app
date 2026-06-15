class LoginRequest {
  LoginRequest({required this.pin});

  final String pin;

  Map<String, dynamic> toJson() => {'pin': pin};
}
