class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class Token {
  final String accessToken;
  final String tokenType;

  const Token({required this.accessToken, required this.tokenType});

  factory Token.fromJson(Map<String, dynamic> json) => Token(
        accessToken: json['access_token'] as String,
        tokenType: json['token_type'] as String? ?? 'bearer',
      );
}

class User {
  final String id;
  final String email;
  final String? fullName;
  final String role;

  const User({
    required this.id,
    required this.email,
    this.fullName,
    required this.role,
  });

  factory User.fromJson(Map<String, dynamic> json) => User(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        role: json['role'] as String? ?? 'sales_rep',
      );

  bool get isAdmin => role == 'admin';
  bool get isManager => role == 'manager' || role == 'admin';
}
