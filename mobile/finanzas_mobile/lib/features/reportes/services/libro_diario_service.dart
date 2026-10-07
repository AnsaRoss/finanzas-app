import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/reportes/models/movimiento_libro_diario.dart';
import 'package:http/http.dart' as http;

class LibroDiarioException implements Exception {
  const LibroDiarioException(this.message);

  final String message;
}

class LibroDiarioService {
  const LibroDiarioService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<List<MovimientoLibroDiario>> listarMovimientos({
    required int espacioId,
    required int anio,
    required int mes,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/Reportes/libro-diario',
      ).replace(
        queryParameters: {
          'espacioId': espacioId.toString(),
          'anio': anio.toString(),
          'mes': mes.toString(),
        },
      );

      final response = await httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        return json
            .map(
              (item) => MovimientoLibroDiario.fromJson(
                item as Map<String, dynamic>,
              ),
            )
            .toList();
      }

      _throwHttpError(response, 'No se pudieron cargar los movimientos.');
    } on FormatException {
      throw const LibroDiarioException(
        'La respuesta de movimientos no es válida.',
      );
    } on http.ClientException {
      throw const LibroDiarioException('No se pudo conectar con el servidor.');
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
      throw const LibroDiarioException('No hay una sesión activa.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Never _throwHttpError(http.Response response, String fallbackMessage) {
    if (response.statusCode == 401) {
      throw const LibroDiarioException(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }

    final responseMessage = response.body.trim();
    if (responseMessage.isNotEmpty) {
      throw LibroDiarioException(responseMessage);
    }

    throw LibroDiarioException(fallbackMessage);
  }
}
