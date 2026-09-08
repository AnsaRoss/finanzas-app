class LoginResponse {
  const LoginResponse({
    required this.usuarioId,
    required this.nombre,
    required this.email,
    required this.token,
  });

  final int usuarioId;
  final String nombre;
  final String email;
  final String token;

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      usuarioId: json['usuarioId'] as int,
      nombre: json['nombre'] as String,
      email: json['email'] as String,
      token: json['token'] as String,
    );
  }
}
