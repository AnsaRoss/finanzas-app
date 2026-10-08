import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/models/login_response.dart';
import 'package:http/http.dart' as http;

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;
}

class AuthService {
  const AuthService({this.client});

  final http.Client? client;

  Future<LoginResponse> login({
    required String email,
    required String password,
  }) async {
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Auth/login'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return LoginResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      if (response.statusCode == 400 || response.statusCode == 401) {
        throw const AuthException('Correo o contraseña incorrectos.');
      }

      throw const AuthException(
        'No se pudo iniciar sesión. Intenta nuevamente.',
      );
    } on FormatException {
      throw const AuthException('La respuesta del servidor no es válida.');
    } on http.ClientException {
      throw const AuthException(
        'No se pudo conectar con el servidor de autenticación.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<LoginResponse> register({
    required String nombre,
    required String email,
    required String password,
  }) async {
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Auth/register'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nombre': nombre,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return LoginResponse.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }

      final responseMessage = response.body.trim();
      if (responseMessage.isNotEmpty) {
        throw AuthException(responseMessage);
      }

      throw const AuthException('No se pudo crear la cuenta.');
    } on FormatException {
      throw const AuthException('La respuesta del registro no es válida.');
    } on http.ClientException {
      throw const AuthException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }
}
