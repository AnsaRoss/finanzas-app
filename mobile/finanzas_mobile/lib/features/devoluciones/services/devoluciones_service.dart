import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/devoluciones/models/devolucion.dart';
import 'package:http/http.dart' as http;

class DevolucionesException implements Exception {
  const DevolucionesException(this.message);

  final String message;
}

class DevolucionesService {
  const DevolucionesService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<List<Devolucion>> listarPorEspacio(int espacioId) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Devoluciones/espacio/$espacioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        return json
            .map((item) => Devolucion.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      _throwHttpError(response, 'No se pudieron cargar las devoluciones.');
    } on FormatException {
      throw const DevolucionesException(
        'La respuesta de devoluciones no es válida.',
      );
    } on http.ClientException {
      throw const DevolucionesException(
        'No se pudo conectar con el servidor.',
      );
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> registrarPago({
    required int id,
    required double valor,
    required DateTime fechaPago,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/Devoluciones/$id/pagar'),
        headers: headers,
        body: jsonEncode({
          'valor': valor,
          'fechaPago': _formatDate(fechaPago),
        }),
      );

      _ensureSuccess(response, 'No se pudo registrar el pago.');
    } on http.ClientException {
      throw const DevolucionesException(
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
      throw const DevolucionesException('No hay una sesión activa.');
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
      throw const DevolucionesException(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }

    final responseMessage = response.body.trim();
    if (responseMessage.isNotEmpty) {
      throw DevolucionesException(responseMessage);
    }

    throw DevolucionesException(fallbackMessage);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
