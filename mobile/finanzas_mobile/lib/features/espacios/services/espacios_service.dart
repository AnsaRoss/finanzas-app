import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/espacios/models/espacio_financiero.dart';
import 'package:http/http.dart' as http;

class EspaciosException implements Exception {
  const EspaciosException(this.message);

  final String message;
}

class EspaciosService {
  const EspaciosService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<List<EspacioFinanciero>> getEspacios() async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Espacios'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        return json
            .map(
              (item) =>
                  EspacioFinanciero.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      }

      if (response.statusCode == 401) {
        throw const EspaciosException(
          'Tu sesión expiró. Vuelve a iniciar sesión.',
        );
      }

      throw const EspaciosException(
        'No se pudieron cargar los espacios financieros.',
      );
    } on FormatException {
      throw const EspaciosException('La respuesta de espacios no es válida.');
    } on http.ClientException {
      throw const EspaciosException(
        'No se pudo conectar con el servidor.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> crearHogar(String nombre) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Espacios/hogar'),
        headers: headers,
        body: jsonEncode({'nombre': nombre}),
      );

      _ensureSuccess(
        response,
        'No se pudo crear el hogar.',
      );
    } on http.ClientException {
      throw const EspaciosException(
        'No se pudo conectar con el servidor.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> agregarMiembro({
    required int espacioId,
    required String email,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Espacios/$espacioId/miembros'),
        headers: headers,
        body: jsonEncode({'email': email}),
      );

      _ensureSuccess(
        response,
        'No se pudo agregar el miembro.',
      );
    } on http.ClientException {
      throw const EspaciosException(
        'No se pudo conectar con el servidor.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<Map<String, String>> _getAuthHeaders() async {
    final session = await sessionService.getSession();
    final token = session?.token;

    if (token == null || token.isEmpty) {
      throw const EspaciosException('No hay una sesión activa.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  void _ensureSuccess(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    if (response.statusCode == 401) {
      throw const EspaciosException(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }

    final responseMessage = response.body.trim();
    if (responseMessage.isNotEmpty) {
      throw EspaciosException(responseMessage);
    }

    throw EspaciosException(fallbackMessage);
  }
}
