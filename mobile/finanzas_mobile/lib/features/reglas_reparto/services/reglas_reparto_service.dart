import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/reglas_reparto/models/regla_reparto.dart';
import 'package:http/http.dart' as http;

class ReglasRepartoException implements Exception {
  const ReglasRepartoException(this.message);

  final String message;
}

class ReglasRepartoService {
  const ReglasRepartoService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<List<ReglaReparto>> listarPorEspacio(int espacioId) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/ReglasReparto/espacio/$espacioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        return json
            .map((item) => ReglaReparto.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      _throwHttpError(response, 'No se pudieron cargar las reglas de reparto.');
    } on FormatException {
      throw const ReglasRepartoException(
        'La respuesta de reglas de reparto no es válida.',
      );
    } on http.ClientException {
      throw const ReglasRepartoException(
        'No se pudo conectar con el servidor.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> guardar({
    required int espacioId,
    required List<ReglaRepartoUpdate> distribuciones,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.put(
        Uri.parse('${ApiConfig.baseUrl}/api/ReglasReparto/espacio/$espacioId'),
        headers: headers,
        body: jsonEncode({
          'distribuciones': distribuciones
              .map(
                (item) => {
                  'usuarioId': item.usuarioId,
                  'porcentaje': item.porcentaje,
                },
              )
              .toList(),
        }),
      );

      _ensureSuccess(response, 'No se pudieron guardar las reglas de reparto.');
    } on http.ClientException {
      throw const ReglasRepartoException(
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
      throw const ReglasRepartoException('No hay una sesión activa.');
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

    _throwHttpError(response, fallbackMessage);
  }

  Never _throwHttpError(http.Response response, String fallbackMessage) {
    if (response.statusCode == 401) {
      throw const ReglasRepartoException(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }

    final responseMessage = response.body.trim();
    if (responseMessage.isNotEmpty) {
      throw ReglasRepartoException(responseMessage);
    }

    throw ReglasRepartoException(fallbackMessage);
  }
}

class ReglaRepartoUpdate {
  const ReglaRepartoUpdate({
    required this.usuarioId,
    required this.porcentaje,
  });

  final int usuarioId;
  final double porcentaje;
}
