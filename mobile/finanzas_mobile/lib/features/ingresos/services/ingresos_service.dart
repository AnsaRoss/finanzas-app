import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/ingresos/models/ingreso.dart';
import 'package:http/http.dart' as http;

class IngresosException implements Exception {
  const IngresosException(this.message);

  final String message;
}

class IngresosService {
  const IngresosService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<List<Ingreso>> listarPorEspacio(int espacioId) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/Ingresos/espacio/$espacioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        return json
            .map((item) => Ingreso.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      _throwHttpError(response, 'No se pudieron cargar los ingresos.');
    } on FormatException {
      throw const IngresosException('La respuesta de ingresos no es válida.');
    } on http.ClientException {
      throw const IngresosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> crearIngreso({
    required int espacioFinancieroId,
    required int usuarioId,
    required int categoriaId,
    required int? cuentaId,
    required String concepto,
    required double valor,
    required DateTime fecha,
    required String? observacion,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/Ingresos'),
        headers: headers,
        body: jsonEncode({
          'espacioFinancieroId': espacioFinancieroId,
          'usuarioId': usuarioId,
          'categoriaId': categoriaId,
          'cuentaId': cuentaId,
          'concepto': concepto,
          'valor': valor,
          'fecha': _formatDate(fecha),
          'observacion': observacion,
        }),
      );

      _ensureSuccess(response, 'No se pudo crear el ingreso.');
    } on http.ClientException {
      throw const IngresosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> editarIngreso({
    required int id,
    required int categoriaId,
    required int? cuentaId,
    required String concepto,
    required double valor,
    required DateTime fecha,
    required String? observacion,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.put(
        Uri.parse('${ApiConfig.baseUrl}/api/Ingresos/$id'),
        headers: headers,
        body: jsonEncode({
          'categoriaId': categoriaId,
          'cuentaId': cuentaId,
          'concepto': concepto,
          'valor': valor,
          'fecha': _formatDate(fecha),
          'observacion': observacion,
        }),
      );

      _ensureSuccess(response, 'No se pudo editar el ingreso.');
    } on http.ClientException {
      throw const IngresosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> anularIngreso(int id) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/Ingresos/$id/anular'),
        headers: headers,
      );

      _ensureSuccess(response, 'No se pudo anular el ingreso.');
    } on http.ClientException {
      throw const IngresosException('No se pudo conectar con el servidor.');
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
      throw const IngresosException('No hay una sesión activa.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };
  }

  Never _throwHttpError(http.Response response, String fallbackMessage) {
    if (response.statusCode == 401) {
      throw const IngresosException(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }

    final responseMessage = response.body.trim();
    if (responseMessage.isNotEmpty) {
      throw IngresosException(responseMessage);
    }

    throw IngresosException(fallbackMessage);
  }

  void _ensureSuccess(http.Response response, String fallbackMessage) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    _throwHttpError(response, fallbackMessage);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
