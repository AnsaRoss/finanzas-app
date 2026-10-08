import 'dart:convert';

import 'package:finanzas_mobile/core/config/api_config.dart';
import 'package:finanzas_mobile/features/auth/services/session_service.dart';
import 'package:finanzas_mobile/features/gastos_fijos/models/gasto_fijo.dart';
import 'package:http/http.dart' as http;

class GastosFijosException implements Exception {
  const GastosFijosException(this.message);

  final String message;
}

class GastosFijosService {
  const GastosFijosService({
    this.client,
    this.sessionService = const SessionService(),
  });

  final http.Client? client;
  final SessionService sessionService;

  Future<List<GastoFijo>> listarPorEspacio(int espacioId) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.get(
        Uri.parse('${ApiConfig.baseUrl}/api/GastosFijos/espacio/$espacioId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as List<dynamic>;

        return json
            .map((item) => GastoFijo.fromJson(item as Map<String, dynamic>))
            .toList();
      }

      _throwHttpError(response, 'No se pudieron cargar los gastos fijos.');
    } on FormatException {
      throw const GastosFijosException(
        'La respuesta de gastos fijos no es válida.',
      );
    } on http.ClientException {
      throw const GastosFijosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> crear({
    required int espacioFinancieroId,
    required int categoriaId,
    required String concepto,
    required double valorEstimado,
    required int diaVencimiento,
    required int tipoReparto,
    required int? responsableId,
    required List<Map<String, Object>> distribucion,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/GastosFijos'),
        headers: headers,
        body: jsonEncode({
          'espacioFinancieroId': espacioFinancieroId,
          'categoriaId': categoriaId,
          'concepto': concepto,
          'valorEstimado': valorEstimado,
          'diaVencimiento': diaVencimiento,
          'tipoReparto': tipoReparto,
          'responsableId': responsableId,
          'distribucion': distribucion,
        }),
      );

      _ensureSuccess(response, 'No se pudo crear el gasto fijo.');
    } on http.ClientException {
      throw const GastosFijosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> editar({
    required int id,
    required int espacioFinancieroId,
    required int categoriaId,
    required String concepto,
    required double valorEstimado,
    required int diaVencimiento,
    required int tipoReparto,
    required int? responsableId,
    required List<Map<String, Object>> distribucion,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.put(
        Uri.parse('${ApiConfig.baseUrl}/api/GastosFijos/$id'),
        headers: headers,
        body: jsonEncode({
          'espacioFinancieroId': espacioFinancieroId,
          'categoriaId': categoriaId,
          'concepto': concepto,
          'valorEstimado': valorEstimado,
          'diaVencimiento': diaVencimiento,
          'tipoReparto': tipoReparto,
          'responsableId': responsableId,
          'distribucion': distribucion,
        }),
      );

      _ensureSuccess(response, 'No se pudo editar el gasto fijo.');
    } on http.ClientException {
      throw const GastosFijosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> cambiarEstado({
    required int id,
    required bool activo,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final uri = Uri.parse(
        '${ApiConfig.baseUrl}/api/GastosFijos/$id/estado',
      ).replace(queryParameters: {'activo': activo.toString()});

      final response = await httpClient.patch(uri, headers: headers);

      _ensureSuccess(response, 'No se pudo cambiar el estado.');
    } on http.ClientException {
      throw const GastosFijosException('No se pudo conectar con el servidor.');
    } finally {
      if (client == null) {
        httpClient.close();
      }
    }
  }

  Future<void> generar({
    required int id,
    required double? valor,
    required DateTime fecha,
    required String? observacion,
  }) async {
    final headers = await _getAuthHeaders();
    final httpClient = client ?? http.Client();

    try {
      final response = await httpClient.post(
        Uri.parse('${ApiConfig.baseUrl}/api/GastosFijos/$id/generar'),
        headers: headers,
        body: jsonEncode({
          'valor': valor,
          'fecha': _formatDate(fecha),
          'observacion': observacion,
        }),
      );

      _ensureSuccess(response, 'No se pudo generar el gasto del mes.');
    } on http.ClientException {
      throw const GastosFijosException('No se pudo conectar con el servidor.');
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
      throw const GastosFijosException('No hay una sesión activa.');
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
      throw const GastosFijosException(
        'Tu sesión expiró. Vuelve a iniciar sesión.',
      );
    }

    final responseMessage = response.body.trim();
    if (responseMessage.isNotEmpty) {
      throw GastosFijosException(responseMessage);
    }

    throw GastosFijosException(fallbackMessage);
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
  }
}
