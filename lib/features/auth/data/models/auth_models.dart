/// VintageVibe Mobile — Auth Data Models
/// Mirrors the Angular frontend auth interfaces and the Spring Boot API contracts.

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {
        'email': email,
        'password': password,
      };
}

class RegisterRequest {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  const RegisterRequest({
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'password': password,
      };
}

class AuthResponse {
  final int id;
  final String token;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final bool? isActive;
  final String role;

  const AuthResponse({
    required this.id,
    required this.token,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.isActive,
    required this.role,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      id: json['id'] as int,
      token: json['token'] as String,
      email: json['email'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      phone: json['phone'] as String?,
      isActive: json['isActive'] as bool?,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'token': token,
        'email': email,
        'firstName': firstName,
        'lastName': lastName,
        'phone': phone,
        'isActive': isActive,
        'role': role,
      };

  String get fullName => '$firstName $lastName';
  bool get isAdmin => role.toUpperCase() == 'ROLE_ADMIN' || role.toUpperCase() == 'ADMIN';
}
