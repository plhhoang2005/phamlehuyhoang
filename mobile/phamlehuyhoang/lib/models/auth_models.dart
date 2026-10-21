class UserDto {
  final String id;
  final String username;
  final String email;
  final String fullName;
  final String? studentCode;
  final String role;
  final bool hasFaceRegistered;
  final bool isActive;

  UserDto({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    this.studentCode,
    required this.role,
    required this.hasFaceRegistered,
    this.isActive = true,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      studentCode: json['studentCode'],
      role: json['role'] ?? 'Student',
      hasFaceRegistered: json['hasFaceRegistered'] ?? false,
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'username': username,
    'email': email,
    'fullName': fullName,
    'studentCode': studentCode,
    'role': role,
    'hasFaceRegistered': hasFaceRegistered,
    'isActive': isActive,
  };
}

class PreAuthResponse {
  final String ticket;
  final String message;
  final int expiresInSeconds;
  final String purpose;

  bool get isActivation => purpose == 'EmailActivation';

  PreAuthResponse({
    required this.ticket,
    required this.message,
    required this.expiresInSeconds,
    this.purpose = 'Login',
  });

  factory PreAuthResponse.fromJson(Map<String, dynamic> json) {
    return PreAuthResponse(
      ticket: json['ticket'] ?? '',
      message: json['message'] ?? '',
      expiresInSeconds: json['expiresInSeconds'] ?? 300,
      purpose: json['purpose'] ?? 'Login',
    );
  }
}

class AuthResponse {
  final String token;
  final UserDto user;

  AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      user: UserDto.fromJson(json['user'] ?? {}),
    );
  }
}
